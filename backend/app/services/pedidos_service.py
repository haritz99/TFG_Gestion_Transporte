import datetime
from typing import Optional, List
from fastapi import HTTPException, Depends
from ..schemas.pedido import PedidoSchema
from app.crud.pedidos_crud import PedidosCRUD
from app.services.cargas_service import CargasService

class PedidosService:
    def __init__(self, crud: PedidosCRUD = Depends(PedidosCRUD), cargas_service: CargasService = Depends(CargasService)):
        self._crud = crud
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

    def create_pedido(self, pedido: PedidoSchema, company_id: str) -> PedidoSchema:
        pedido.companyId = company_id
        pedido.id = self._crud.create_pedido_doc(pedido.model_dump())
        return pedido

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
