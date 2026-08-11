from datetime import datetime, timezone, time, timedelta
from typing import Optional, List

import pytz
from fastapi import HTTPException, Depends
from ..schemas.carga import CargaSchema, EstadoCarga, TipoCargaSchema, CargaUpdateSubSchema
from ..schemas.vehiculos import VehiculoSchema
from app.dependencies.repositories import get_cargas_repository, get_pedidos_repository, get_user_repository, get_vehiculos_repository
from app.interfaces.i_cargas_repository import ICargasRepository
from app.interfaces.i_pedidos_repository import IPedidosRepository
from app.interfaces.i_repository import IRepository
from app.interfaces.i_user_repository import IUserRepository
from app.schemas.pedido import PedidoSchema
from ..schemas.carga import CartaDePorteSnapshotSchema
from app.schemas.external_user import SubcontratadoSchema
from google.cloud.firestore import ArrayUnion
from .notification_service import NotificacionService

class CargasService:
    def __init__(self, crud: ICargasRepository = Depends(get_cargas_repository), pedidos_crud: IPedidosRepository = Depends(get_pedidos_repository), users_crud: IUserRepository = Depends(get_user_repository), vehiculos_crud: IRepository = Depends(get_vehiculos_repository), notificacion_service: NotificacionService = Depends(NotificacionService)):
        self._crud = crud
        self._pedidos_crud = pedidos_crud
        self._users_crud = users_crud
        self._vehiculos_crud = vehiculos_crud
        self._notificacion_service = notificacion_service

    def fetch_cargas(self, company_id: str, cliente_id: Optional[str] = None, pedido_id: Optional[str] = None, transportista_id: Optional[str] = None, estado: Optional[EstadoCarga] = None, fecha_inicio: Optional[datetime.date] = None, fecha_fin: Optional[datetime.date] = None) -> List[CargaSchema]:
        dt_inicio = datetime.combine(fecha_inicio, time.min) if fecha_inicio else None
        dt_fin = datetime.combine(fecha_fin, time.max) if fecha_fin else None

        docs = self._crud.get_all(company_id, cliente_id, pedido_id, transportista_id, estado.value if estado else None, dt_inicio, dt_fin)
        return [CargaSchema.from_firestore(doc, company_id) for doc in docs]

    def get_tipos_carga(self, company_id: str, cliente_id: str):
        docs = self._crud.get_tipos_cargas(company_id, cliente_id)
        print("docs: ", docs)
        return [TipoCargaSchema.from_firestore(doc, company_id) for doc in docs]

    def create_tipo_carga(self, company_id: str, tipo_carga: TipoCargaSchema):
        payload = tipo_carga.model_dump()
        payload["companyId"] = company_id
        now = datetime.now(timezone.utc)
        payload["createdAt"] = now
        payload["updatedAt"] = now
        data = self._crud.create_tipo_carga(payload)
        return TipoCargaSchema(**data)


    def calculate_asignados(self, company_id: str):
        inicio, fin = self._limites_semana_actual()
        result = self._crud.get_cargas_count(company_id, EstadoCarga.ASIGNADO.value, inicio, fin)
        if result and len(result) > 0 and len(result[0]) > 0:
            return result[0][0].value
        return 0

    def calculate_sin_asignar(self, company_id: str):
        inicio, fin = self._limites_semana_actual()
        result = self._crud.get_cargas_count(company_id, EstadoCarga.PLANIFICADO.value, inicio, fin)
        if result and len(result) > 0 and len(result[0]) > 0:
            return result[0][0].value
        return 0

    @staticmethod
    def _limites_semana_actual() -> tuple[datetime, datetime]:
        ahora = datetime.now(timezone.utc)
        inicio_semana = ahora - timedelta(days=ahora.weekday())
        inicio_semana = inicio_semana.replace(hour=0, minute=0, second=0, microsecond=0)
        fin_semana = inicio_semana + timedelta(days=6, hours=23, minutes=59, seconds=59)
        return inicio_semana, fin_semana

    def calculate_cargas_hoy(self, company_id: str, sod: datetime, eod: datetime, estado: Optional[EstadoCarga] = None):
        if sod.tzinfo is None: sod = pytz.utc.localize(sod)
        if eod.tzinfo is None: eod = pytz.utc.localize(eod)
        result = self._crud.get_cargas_hoy_count(company_id, sod, eod, estado.value if estado else None)
        if result and len(result) > 0 and len(result[0]) > 0:
            return result[0][0].value
        return 0

    def get_carga_by_id(self, carga_id: str, company_id: str) -> CargaSchema:
        doc = self._crud.get_by_id(company_id, carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")
        return CargaSchema.from_firestore(doc, company_id)

    def update_carga_sub(self, carga_id: str, carga: CargaUpdateSubSchema, sub_company_id: str) -> CargaSchema:

        doc = self._crud.get_by_id(sub_company_id, carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga_data = doc.to_dict() or {}

        update_data = carga.model_dump(exclude_none=True)
        if not update_data:
            raise HTTPException(status_code=400, detail="No hay campos para actualizar")

        snapshot_fields = {}
        for field in ['conductorNombre', 'subVehiculoMatricula', 'subRemolqueMatricula']:
            if field in update_data:
                snapshot_fields[field] = update_data.pop(field)

        snapshot_actual = carga_data.get('cartaPorteSnapshot', {}) or {}
        update_data['cartaPorteSnapshot'] = {**snapshot_actual, **snapshot_fields}
        update_data["updatedAt"] = datetime.now(timezone.utc)

        self._crud.update(sub_company_id, carga_id, update_data)

        updated_doc = self._crud.get_by_id(sub_company_id, carga_id)
        return CargaSchema.from_firestore(updated_doc, carga_data.get("companyId"))

    def bulk_update_cargas(self, cargas: List[CargaSchema], company_id: str) -> List[CargaSchema]:
        batch = self._crud.get_batch()
        for carga in cargas:
            if not carga.pedidoId:
                raise HTTPException(status_code=400, detail=f"La carga {carga.id} debe estar asociada a un pedido")

        pedido_ids_unicos = {carga.pedidoId for carga in cargas}
        pedido_refs = [self._pedidos_crud.get_pedido_ref(pid) for pid in pedido_ids_unicos]
        pedidos_docs = self._pedidos_crud.get_pedidos_by_refs(company_id, pedido_refs)
        pedidos_por_id: dict[str, PedidoSchema] = {}
        for doc in pedidos_docs:
            if not doc.exists:
                raise HTTPException(status_code=404, detail=f"Pedido {doc.id} no encontrado")
            pedidos_por_id[doc.id] = PedidoSchema.from_firestore(doc, company_id)

        for carga in cargas:
            pedido_schema = pedidos_por_id.get(carga.pedidoId)

            try:
                carga.validar_contra_pedido(pedido_schema)
            except ValueError as exc:
                raise HTTPException(status_code=400, detail=str(exc))

            if carga.vehiculoId:
                self.validar_asignacion_vehiculo(carga, company_id)

            carga.companyId = company_id
            carga.clienteId = pedido_schema.clienteId

            ref = self._crud.get_carga_ref(company_id, carga.id)
            if ref is None:
                raise HTTPException(status_code=500, detail=f"No se pudo obtener la referencia de la carga {carga.id}")
            batch.update(ref, carga.model_dump(exclude={'id'}))

        batch.commit()

        for carga in cargas:
            if carga.transportistaId:
                self._notificacion_service.notificar(
                    user_id=carga.transportistaId,
                    roles=["transportista"],
                    titulo="Carga replanificada",
                    cuerpo=f"Tu carga {carga.id} de {carga.origen.direccion.ciudad} a {carga.destino.direccion.ciudad} ha sido replanificada, accede a la app para ver los cambios.",
                    data={
                        "evento": "carga_replanificada",
                        "cargaId": carga.id,
                    },
                    company_id=company_id,
                )

        return cargas

    def validar_asignacion_vehiculo(self, carga: CargaSchema, company_id: str):
        vehiculo_doc = self._vehiculos_crud.get_by_id(company_id, carga.vehiculoId)
        vehiculo = VehiculoSchema.from_firestore(vehiculo_doc, company_id)
        try:
            carga.validar_contra_vehiculo(vehiculo)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail=str(exc))

    def update_buffer_hours(self, carga_id: str, buffer_hours: int, company_id: str):
        doc = self._crud.get_by_id(company_id, carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        self._crud.update(company_id, carga_id, {"bufferHours": buffer_hours, "updatedAt": datetime.now(timezone.utc)})


    def ceder_carga_subcontratado(self, carga_id: str, subcontratado_id: str, company_id: str, comision: float = 3.0) -> CargaSchema:
        doc = self._crud.get_by_id(company_id, carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")
        carga = CargaSchema.from_firestore(doc, company_id)
        sub_doc = self._users_crud.get_subcontratado_by_id(company_id, subcontratado_id)
        if not sub_doc.exists:
            raise HTTPException(status_code=404, detail="Subcontratado no encontrado")

        sub_data = sub_doc.to_dict() or {}

        subcontratado = SubcontratadoSchema(**{**sub_data, "uid": sub_doc.id})

        precio_neto = round(carga.precio * (1 - comision / 100), 2)

        snapshot = carga.cartaPorteSnapshot
        update_payload = self._rellenar_snapshot_subcontratado(snapshot, subcontratado, comision, precio_neto)

        batch = self._crud.get_batch()
        carga_ref = doc.reference
        batch.update(carga_ref, update_payload)

        batch.update(sub_doc.reference, {
            "cargasCedidas": ArrayUnion([carga_id])
        })

        batch.commit()

        updated_doc = self._crud.get_by_id(company_id, carga_id)
        self._notificacion_service.notificar(
            user_id=subcontratado.uid,
            roles=["subcontratado"],
            titulo="Carga cedida",
            cuerpo=f"Se te ha cedido una carga, entra en la app para conocer los detalles!.",
            data={
                "evento": "carga_cedida",
                "cargaId": carga_id,
                "subcontratadoId": subcontratado.uid,
            },
            company_id=company_id,
        )
        return CargaSchema.from_firestore(updated_doc, company_id)

    @staticmethod
    def _rellenar_snapshot_subcontratado(snapshot: CartaDePorteSnapshotSchema, subcontratado: SubcontratadoSchema, comision: float, precio_neto: float) -> dict:
        direccion = subcontratado.direccionFiscal
        direccion_format = f"{direccion.calle}, {direccion.codigoPostal} {direccion.ciudad} ({direccion.provincia})"

        snapshot.subcontratadoNombre = subcontratado.nombreComercial
        snapshot.subcontratadoNif = subcontratado.nif
        snapshot.subcontratadoDireccion = direccion_format
        snapshot.subcontratadoTelefono = subcontratado.telefono
        snapshot.subcontratadoNumAutorizacion = subcontratado.numeroAutorizacion
        snapshot.precioNeto = precio_neto

        update_payload = {
            "cartaPorteSnapshot": snapshot.model_dump(),
            "estado": EstadoCarga.CEDIDO.value,
            "updatedAt": datetime.now(timezone.utc),
            "transportistaId": None,
            "conductorNombre": None,
            "subcontratadoId": subcontratado.uid,
            "subVehiculoMatricula": None,
            "subRemolqueMatricula": None,
            'comisionCesion': comision,
        }
        return update_payload

    def update_estado_carga(self, carga_id: str, nuevo_estado: str, company_id: str) -> CargaSchema:
        doc = self._crud.get_by_id(company_id, carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        self._crud.update(company_id, carga_id, {
            "estado": nuevo_estado,
            "updatedAt": datetime.now(timezone.utc)
        })

        updated_doc = self._crud.get_by_id(company_id, carga_id)
        return CargaSchema.from_firestore(updated_doc, company_id)


    def delete_carga(self, carga_id: str, company_id: str):
        doc = self._crud.get_by_id(company_id, carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga_data = doc.to_dict()

        estado_actual = carga_data.get("estado")
        if estado_actual in [EstadoCarga.EN_TRANSITO.value, EstadoCarga.ENTREGADO.value]:
            raise HTTPException(status_code=400, detail=f"No se puede eliminar una carga en estado {estado_actual}.")

        self._crud.delete(company_id, carga_id)

    def fetch_cargas_cedidas(self, subcontratado_id: str, company_id: str) -> list[CargaSchema]:
        user_doc = self._users_crud.get_subcontratado_by_id(company_id, subcontratado_id)
        if not user_doc.exists:
            return []
        user_data = user_doc.to_dict()
        cargas_cedidas_ids = user_data.get("cargasCedidas", [])
        if not cargas_cedidas_ids:
            return []
        docs = self._crud.get_cargas_by_ids(company_id, cargas_cedidas_ids)
        return [CargaSchema.from_firestore(doc, company_id) for doc in docs]