import datetime
from typing import Optional, List
from fastapi import HTTPException, Depends

from ..crud.cargas_crud import CargasCRUD
from ..crud.user_crud import UserCRUD
from ..schemas.carga import TipoCargaSchema, CargaSchema, EstadoCarga, CartaDePorteSnapshotSchema
from ..schemas.pedido import PedidoSchema, CreatePedidoSchema
from app.crud.pedidos_crud import PedidosCRUD
from app.services.cargas_service import CargasService
from ..schemas.external_user import ClienteSchema

class PedidosService:
    def __init__(self, crud: PedidosCRUD = Depends(PedidosCRUD),
                 cargas_crud: CargasCRUD = Depends(CargasCRUD),
                 cargas_service: CargasService = Depends(CargasService),
                 users_crud: UserCRUD = Depends(UserCRUD)):
        self._crud = crud
        self._cargas_crud = cargas_crud
        self._cargas_service = cargas_service
        self._users_crud = users_crud

    def fetch_pedidos(self, company_id: str, cliente_id: Optional[str] = None, estado: Optional[str] = None, fecha_inicio: Optional[datetime.date] = None, fecha_fin: Optional[datetime.date] = None) -> List[PedidoSchema]:
        dt_inicio = datetime.datetime.combine(fecha_inicio, datetime.time.min) if fecha_inicio else None
        dt_fin = datetime.datetime.combine(fecha_fin, datetime.time.max) if fecha_fin else None
        
        docs = self._crud.get_todos_los_pedidos(company_id, cliente_id, estado, dt_inicio, dt_fin)
        return [PedidoSchema.from_firestore(doc, company_id) for doc in docs]

    def get_pedido_by_id(self, pedido_id: str, company_id: str) -> PedidoSchema:
        doc = self._crud.get_pedido_doc(pedido_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Pedido no encontrado")
        return PedidoSchema.from_firestore(doc, company_id)

    def create_pedido(self, pedido: CreatePedidoSchema, company_id: str):
        pedido.companyId = company_id
        pedido_payload = pedido.model_dump(exclude={'cargas', 'id'})
        
        cargas_payloads = []

        snapshot = self._preparar_snapshot(pedido, company_id)

        for asig in pedido.cargas:
            tipo_doc = self._cargas_crud.get_tipo_carga_by_id(asig.tipoCargaId)
            tipo = TipoCargaSchema.from_firestore(tipo_doc, company_id)

            if asig.transportistaId and asig.vehiculoId:
                estado = EstadoCarga.ASIGNADO
            else:
                estado = EstadoCarga.PENDIENTE

            carga = CargaSchema(
                origen=tipo.origen,
                destino=tipo.destino,
                mercancia=tipo.mercancia,
                numBultos=tipo.numBultos,
                peso=tipo.peso,
                precio=tipo.precio,
                largo=tipo.largo,
                ancho=tipo.ancho,
                alto=tipo.alto,
                fechaCarga=asig.fechaCarga or pedido.fechaCarga,
                fechaDescarga=asig.fechaDescarga or pedido.fechaDescarga,
                transportistaId=asig.transportistaId,
                conductorNombre=asig.conductorNombre,
                vehiculoId=asig.vehiculoId,
                pedidoId=None, # Lo asigno después de manera transaccional
                clienteId=pedido.clienteId,
                cartaPorteSnapshot=snapshot,
                estado=estado,
                companyId=company_id,
                createdAt=datetime.datetime.now(),
                updatedAt=datetime.datetime.now()
            )
            cargas_payloads.append(carga.model_dump(exclude={'id'}))

        result = self._crud.create_pedido_con_cargas(pedido_payload, cargas_payloads)
        pedido.id = result["pedidoId"]

        # Actualizar referencias cruzadas y estados de transportistas y vehículos
        if result.get("cargas"):
            self._actualizar_referencias_cruzadas(result["cargas"]) 

        return result

    def _preparar_snapshot(self, pedido: CreatePedidoSchema, company_id: str) -> CartaDePorteSnapshotSchema:
        cliente_id = pedido.clienteId
        cliente_doc = self._users_crud.get_cliente_by_id(cliente_id)
        cliente = ClienteSchema.from_firestore(cliente_doc, company_id)

        direccion_cargador_format = f"{cliente.direccionFiscal.calle}, {cliente.direccionFiscal.codigoPostal} {cliente.direccionFiscal.ciudad} ({cliente.direccionFiscal.provincia})"

        return CartaDePorteSnapshotSchema(
            destinatarioNombre=pedido.destinatarioNombre,
            destinatarioNif=pedido.destinatarioNif,
            destinatarioDireccion=pedido.destinatarioDireccion,
            clienteNombre=cliente.nombreComercial,
            clienteNif=cliente.nif,
            clienteDireccion=direccion_cargador_format,
            clienteTelefono=cliente.telefono,
            congeladoAt=None
        )

    def _actualizar_referencias_cruzadas(self, cargas_creadas: list[dict]):
        batch = self._crud.get_batch() if hasattr(self._crud, 'get_batch') else self._users_crud.get_batch() if hasattr(self._users_crud, 'get_batch') else None

        if not batch:
            from ..firebase_config import db
            batch = db.batch()

        for carga in cargas_creadas:
            carga_id = carga.get("id")
            transportista_id = carga.get("transportistaId")
            vehiculo_id = carga.get("vehiculoId")

            if transportista_id or vehiculo_id:
                estado_veh = "asignado"
                if transportista_id and vehiculo_id:
                    estado_trans = "asignado"
                else:
                    estado_trans = "asignacion_parcial"

                if transportista_id:
                    from ..firebase_config import db
                    trans_ref = db.collection("users").document(transportista_id)
                    trans_update = {
                        "estado": estado_trans,
                        "cargaId": carga_id
                    }
                    if vehiculo_id:
                        trans_update["vehiculoId"] = vehiculo_id
                    batch.update(trans_ref, trans_update)

                if vehiculo_id:
                    from ..firebase_config import db
                    veh_ref = db.collection("vehiculos").document(vehiculo_id)
                    veh_update = {
                        "estado": estado_veh,
                        "cargaId": carga_id
                    }
                    if transportista_id:
                        veh_update["transportistaId"] = transportista_id
                        veh_update["transportistaNombre"] = carga.get("conductorNombre")
                    batch.update(veh_ref, veh_update)

        batch.commit()

    def delete_pedido(self, pedido_id: str, company_id: str):
        doc = self._crud.get_pedido_doc(pedido_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Pedido no encontrado")

        pedido_data = doc.to_dict()
        if pedido_data.get("companyId") != company_id:
            raise HTTPException(status_code=403, detail="No autorizado para eliminar este pedido")

        estado_actual = pedido_data.get("estado")
        if estado_actual in ["planificado", "en_progreso"]:
            raise HTTPException(
                status_code=400,
                detail="No se puede eliminar un pedido en estado PLANIFICADO o EN_PROGRESO."
            )

        # Borrado en cascada
        cargas_asociadas = self._cargas_service.fetch_cargas(company_id=company_id, pedido_id=pedido_id)
        pedido_ref = self._crud.get_pedido_ref(pedido_id)
        cargas_refs = [self._crud.get_carga_ref(c.id) for c in cargas_asociadas if c.id]

        try:
            self._crud.delete_pedido_y_cargas(pedido_ref, cargas_refs)
        except Exception as exc:
            raise HTTPException(
                status_code=500,
                detail=f"Error al eliminar el pedido y sus cargas asociadas: {exc}"
            )
