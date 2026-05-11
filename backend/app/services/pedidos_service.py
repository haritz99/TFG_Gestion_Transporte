import datetime
from typing import Optional, List
from fastapi import HTTPException, Depends

from ..crud.cargas_crud import CargasCRUD
from ..schemas.carga import TipoCargaSchema, CargaSchema, EstadoCarga
from ..schemas.pedido import PedidoSchema, CreatePedidoSchema
from app.crud.pedidos_crud import PedidosCRUD
from app.services.cargas_service import CargasService

class PedidosService:
    def __init__(self, crud: PedidosCRUD = Depends(PedidosCRUD),
                 cargas_crud: CargasCRUD = Depends(CargasCRUD),
                 cargas_service: CargasService = Depends(CargasService)):
        self._crud = crud
        self._cargas_crud = cargas_crud
        self._cargas_service = cargas_service

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
        pedido.id = self._crud.create_pedido_doc(pedido.model_dump(exclude={'cargas', 'id'}))

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
                fechaCarga=pedido.fechaCarga,
                fechaDescarga=pedido.fechaDescarga,
                transportistaId=asig.transportistaId,
                vehiculoId=asig.vehiculoId,
                pedidoId=pedido.id,
                clienteId=pedido.clienteId,
                estado=estado,
                companyId=company_id
            )
            carga.id = self._cargas_crud.create_carga_doc(carga.model_dump(exclude={'id'}))


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
