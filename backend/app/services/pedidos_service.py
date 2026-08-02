import datetime
from typing import Optional, List
from fastapi import HTTPException, Depends

from ..schemas.carga import TipoCargaSchema, CargaSchema, EstadoCarga, CartaDePorteSnapshotSchema
from ..schemas.direccion import DireccionSchema
from ..schemas.pedido import PedidoSchema, CreatePedidoSchema
from app.dependencies.repositories import get_cargas_repository, get_pedidos_repository, get_user_repository
from app.interfaces.i_cargas_repository import ICargasRepository
from app.interfaces.i_pedidos_repository import IPedidosRepository
from app.interfaces.i_user_repository import IUserRepository
from app.services.cargas_service import CargasService
from app.services.notification_service import NotificacionService
from ..schemas.external_user import ClienteSchema

class PedidosService:
    def __init__(self, crud: IPedidosRepository = Depends(get_pedidos_repository),
                 cargas_crud: ICargasRepository = Depends(get_cargas_repository),
                 cargas_service: CargasService = Depends(CargasService),
                 users_crud: IUserRepository = Depends(get_user_repository),
                 notificacion_service: NotificacionService = Depends(NotificacionService)):
        self._crud = crud
        self._cargas_crud = cargas_crud
        self._cargas_service = cargas_service
        self._users_crud = users_crud
        self._notificacion_service = notificacion_service

    def fetch_pedidos(self, company_id: str, cliente_id: Optional[str] = None, estado: Optional[str] = None, fecha_inicio: Optional[datetime.date] = None, fecha_fin: Optional[datetime.date] = None) -> List[PedidoSchema]:
        dt_inicio = datetime.datetime.combine(fecha_inicio, datetime.time.min) if fecha_inicio else None
        dt_fin = datetime.datetime.combine(fecha_fin, datetime.time.max) if fecha_fin else None
        
        docs = self._crud.get_all(company_id, cliente_id, estado, dt_inicio, dt_fin)
        return [PedidoSchema.from_firestore(doc, company_id) for doc in docs]

    def get_pedido_by_id(self, pedido_id: str, company_id: str) -> PedidoSchema:
        doc = self._crud.get_by_id(company_id, pedido_id)
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
            try:
                carga.validar_contra_pedido(pedido)
            except ValueError as exc:
                raise HTTPException(status_code=400, detail=str(exc))
            cargas_payloads.append(carga.model_dump(exclude={'id'}))

        result = self._crud.create(company_id, pedido_payload, cargas_payloads)
        pedido.id = result["pedidoId"]

        for carga_creada in result.get("cargas", []):
            transportista_id = carga_creada.get("transportistaId")
            if not transportista_id:
                continue
            self._notificacion_service.notificar(
                user_id=transportista_id,
                roles=["transportista"],
                titulo="Carga asignada",
                cuerpo=f"Se te ha asignado una nueva carga, entra en la app para ver los detalles!.",
                data={
                    "evento": "carga_asignada",
                    "cargaId": carga_creada.get("id"),
                    "pedidoId": pedido.id,
                },
                company_id=company_id,
            )

        return result

    def _preparar_snapshot(self, pedido: CreatePedidoSchema, company_id: str) -> CartaDePorteSnapshotSchema:
        cliente_id = pedido.clienteId
        cliente_doc = self._users_crud.get_cliente_by_id(cliente_id)
        cliente = ClienteSchema.from_firestore(cliente_doc, company_id)

        direccion_cargador_format = DireccionSchema.format_direccion(cliente.direccionFiscal.model_dump() if cliente.direccionFiscal else None)

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

    def delete_pedido(self, pedido_id: str, company_id: str):
        doc = self._crud.get_by_id(company_id, pedido_id)
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

        # Borrado en cascada (pedido y sus cargas asociadas)
        try:
            self._crud.delete(company_id, pedido_id)
        except Exception as exc:
            raise HTTPException(
                status_code=500,
                detail=f"Error al eliminar el pedido y sus cargas asociadas: {exc}"
            )
