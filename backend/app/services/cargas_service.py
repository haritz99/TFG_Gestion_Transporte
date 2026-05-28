import datetime
import pytz
from typing import Optional, List
from fastapi import HTTPException, Depends
from ..schemas.carga import CargaSchema, EstadoCarga, TipoCargaSchema, CargaUpdateSubSchema
from app.crud.cargas_crud import CargasCRUD
from app.crud.pedidos_crud import PedidosCRUD
from app.crud.user_crud import UserCRUD
from app.schemas.pedido import PedidoSchema
from ..schemas.carga import CartaDePorteSnapshotSchema
from app.schemas.external_user import SubcontratadoSchema
from google.cloud.firestore import ArrayUnion


class CargasService:
    def __init__(self, crud: CargasCRUD = Depends(CargasCRUD), pedidos_crud: PedidosCRUD = Depends(PedidosCRUD), users_crud: UserCRUD = Depends(UserCRUD)):
        self._crud = crud
        self._pedidos_crud = pedidos_crud
        self._users_crud = users_crud

    def fetch_cargas(self, company_id: str, cliente_id: Optional[str] = None, pedido_id: Optional[str] = None, transportista_id: Optional[str] = None, estado: Optional[EstadoCarga] = None, fecha_inicio: Optional[datetime.date] = None, fecha_fin: Optional[datetime.date] = None) -> List[CargaSchema]:
        dt_inicio = datetime.datetime.combine(fecha_inicio, datetime.time.min) if fecha_inicio else None
        dt_fin = datetime.datetime.combine(fecha_fin, datetime.time.max) if fecha_fin else None
        
        docs = self._crud.get_todas_las_cargas(company_id, cliente_id, pedido_id, transportista_id, estado.value if estado else None, dt_inicio, dt_fin)
        return [CargaSchema.from_firestore(doc, company_id) for doc in docs]

    def get_tipos_carga(self, company_id: str, cliente_id: str):
        docs = self._crud.get_tipos_cargas(company_id, cliente_id)
        print("docs: ", docs)
        return [TipoCargaSchema.from_firestore(doc, company_id) for doc in docs]

    def calculate_asignados(self, company_id: str):
        result = self._crud.get_cargas_count(company_id, EstadoCarga.ASIGNADO.value)
        if result and len(result) > 0 and len(result[0]) > 0:
            return result[0][0].value
        return 0

    def calculate_sin_asignar(self, company_id: str):
        result = self._crud.get_cargas_count(company_id, EstadoCarga.PENDIENTE.value)
        if result and len(result) > 0 and len(result[0]) > 0:
            return result[0][0].value
        return 0

    def calculate_cargas_hoy(self, company_id: str, sod: datetime.datetime, eod: datetime.datetime, estado: Optional[EstadoCarga] = None):
        if sod.tzinfo is None: sod = pytz.utc.localize(sod)
        if eod.tzinfo is None: eod = pytz.utc.localize(eod)
        result = self._crud.get_cargas_hoy_count(company_id, sod, eod, estado.value if estado else None)
        if result and len(result) > 0 and len(result[0]) > 0:
            return result[0][0].value
        return 0

    def get_carga_by_id(self, carga_id: str, company_id: str) -> CargaSchema:
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")
        return CargaSchema.from_firestore(doc, company_id)

    def assign_carga_transportista(self, carga_id: str, transportista_id: str, company_id: str) -> CargaSchema:
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga = CargaSchema.from_firestore(doc, company_id)

        trans_doc = self._crud.get_trans_doc(transportista_id)
        trans_data = trans_doc.to_dict() if (trans_doc and trans_doc.exists) else None
        if not trans_data or trans_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        roles = trans_data.get("roles", trans_data.get("rol", []))
        if isinstance(roles, str):
            roles = [roles]
        if not roles or "transportista" not in roles:
            raise HTTPException(status_code=403, detail="El usuario no tiene rol de transportista")
            
        carga.transportistaId = transportista_id
        update_data = {"transportistaId": transportista_id}

        if carga.estado == EstadoCarga.PENDIENTE:
            carga.estado = EstadoCarga.ASIGNADO
            update_data["estado"] = EstadoCarga.ASIGNADO.value
            
        self._crud.update_carga_doc(carga_id, update_data)
        return carga

    def update_carga(self, carga_id: str, carga: CargaSchema, pedido_schema: PedidoSchema, company_id: str) -> CargaSchema:
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga_data = doc.to_dict()
        if carga_data.get("companyId") != company_id:
            raise HTTPException(status_code=403, detail="No autorizado para modificar esta carga")

        carga.companyId = company_id
        carga.id = carga_id
            
        try:
            carga.validar_contra_pedido(pedido_schema)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

        carga.clienteId = pedido_schema.clienteId
        update_data = carga.model_dump(exclude={'id'})
        
        self._crud.update_carga_doc(carga_id, update_data)
        return carga


    @staticmethod
    def _calcular_estado_sub(carga: CargaUpdateSubSchema, carga_data: dict) -> str:
        if carga.estado is not None:
            return carga.estado.value

        conductor_id = carga.transportistaId or carga_data.get("transportistaId")
        vehiculo_sub = carga.subVehiculoMatricula or carga_data.get("subVehiculoMatricula")

        if conductor_id and vehiculo_sub:
            return EstadoCarga.ASIGNADO.value
        return carga_data.get("estado", EstadoCarga.CEDIDO.value)


    def update_carga_sub(self, carga_id: str, carga: CargaUpdateSubSchema, sub_company_id: str) -> CargaSchema:

        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga_data = doc.to_dict() or {}

        if carga_data.get("companyId") != sub_company_id:
            raise HTTPException(status_code=403, detail="No autorizado para modificar esta carga")

        update_data = carga.model_dump(exclude_none=True)
        if not update_data:
            raise HTTPException(status_code=400, detail="No hay campos para actualizar")

        update_data["estado"] = self._calcular_estado_sub(carga, carga_data)
        update_data["updatedAt"] = datetime.datetime.now(datetime.timezone.utc)

        self._crud.update_carga_doc(carga_id, update_data)

        updated_doc = self._crud.get_carga_doc(carga_id)
        return CargaSchema.from_firestore(updated_doc, carga_data.get("companyId"))

    def bulk_update_cargas(self, cargas: List[CargaSchema], company_id: str) -> List[CargaSchema]:
        batch = self._crud.get_batch()
        validated: List[CargaSchema] = []
        for carga in cargas:
            doc = self._crud.get_carga_doc(carga.id)
            if not doc.exists:
                raise HTTPException(status_code=404, detail=f"Carga {carga.id} no encontrada")

            carga_data = doc.to_dict()
            if carga_data.get("companyId") != company_id:
                raise HTTPException(status_code=403, detail=f"No autorizado para modificar la carga {carga.id}")

            if not carga.pedidoId:
                raise HTTPException(status_code=400, detail=f"La carga {carga.id} debe estar asociada a un pedido")

            pedido_doc = self._pedidos_crud.get_pedido_doc(carga.pedidoId)
            if not pedido_doc.exists:
                raise HTTPException(status_code=404, detail=f"Pedido {carga.pedidoId} no encontrado")

            pedido_schema = PedidoSchema.from_firestore(pedido_doc, company_id)

            carga.companyId = company_id
            carga.clienteId = pedido_schema.clienteId
            validated.append(carga)

        for carga in validated:
            ref = self._crud.get_carga_ref(carga.id)
            if ref is None:
                raise HTTPException(status_code=500, detail=f"No se pudo obtener la referencia de la carga {carga.id}")
            batch.update(ref, carga.model_dump(exclude={'id'}))

        batch.commit()

        return validated

    def ceder_carga_subcontratado(self, carga_id: str, subcontratado_id: str, company_id: str) -> CargaSchema:
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")
        carga = CargaSchema.from_firestore(doc, company_id)
        sub_doc = self._users_crud.get_subcontratado_by_id(subcontratado_id)
        if not sub_doc.exists:
            raise HTTPException(status_code=404, detail="Subcontratado no encontrado")

        sub_data = sub_doc.to_dict() or {}
        if sub_data.get("companyId") != company_id:
            raise HTTPException(status_code=403, detail="No autorizado para ceder esta carga al subcontratado")

        subcontratado = SubcontratadoSchema(**{**sub_data, "uid": sub_doc.id})
        snapshot = carga.cartaPorteSnapshot
        update_payload = self._rellenar_snapshot_subcontratado(snapshot, subcontratado)

        batch = self._crud.get_batch()
        carga_ref = doc.reference
        batch.update(carga_ref, update_payload)

        batch.update(sub_doc.reference, {
            "cargasCedidas": ArrayUnion([carga_id])
        })

        batch.commit()

        updated_doc = self._crud.get_carga_doc(carga_id)
        return CargaSchema.from_firestore(updated_doc, company_id)

    @staticmethod
    def _rellenar_snapshot_subcontratado(snapshot: CartaDePorteSnapshotSchema, subcontratado: SubcontratadoSchema) -> dict:
        direccion = subcontratado.direccion
        direccion_format = f"{direccion.calle}, {direccion.codigoPostal} {direccion.ciudad} ({direccion.provincia})"

        snapshot.subcontratadoNombre = subcontratado.nombreComercial
        snapshot.subcontratadoNif = subcontratado.nif
        snapshot.subcontratadoDireccion = direccion_format
        snapshot.subcontratadoTelefono = subcontratado.telefono
        snapshot.subcontratadoNumAutorizacion = subcontratado.numeroAutorizacion
        snapshot.congeladoAt = datetime.datetime.now(datetime.timezone.utc)

        update_payload = {
            "cartaPorteSnapshot": snapshot.model_dump(),
            "estado": EstadoCarga.CEDIDO.value,
            "updatedAt": datetime.datetime.now(datetime.timezone.utc),
            "transportistaId": None,
            "conductorNombre": None,
            "subVehiculoMatricula": None,
            "subRemolqueMatricula": None,
        }
        return update_payload


    def delete_carga(self, carga_id: str, company_id: str):
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga_data = doc.to_dict()
        if carga_data.get("companyId") != company_id:
            raise HTTPException(status_code=403, detail="No autorizado para eliminar esta carga")

        estado_actual = carga_data.get("estado")
        if estado_actual in [EstadoCarga.EN_TRANSITO.value, EstadoCarga.ENTREGADO.value]:
            raise HTTPException(status_code=400, detail=f"No se puede eliminar una carga en estado {estado_actual}.")

        self._crud.delete_carga_doc(carga_id)

    def fetch_cargas_cedidas(self, subcontratado_id: str) -> list[CargaSchema]:
        user_doc = self._users_crud.get_subcontratado_by_id(subcontratado_id)
        if not user_doc.exists:
            return []
        user_data = user_doc.to_dict()
        cargas_cedidas_ids = user_data.get("cargasCedidas", [])
        if not cargas_cedidas_ids:
            return []
        docs = self._crud.get_cargas_by_ids(cargas_cedidas_ids)
        return [CargaSchema.from_firestore(doc, doc.to_dict().get("companyId")) for doc in docs]
