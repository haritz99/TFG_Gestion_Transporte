from fastapi import HTTPException, Depends
from .auth import get_current_encargado
from ..firebase_config import db
from ..schemas.pedido import PedidoSchema
from ..schemas.carga import CargaSchema

def get_pedido_from_carga(
        carga: CargaSchema,
        current_user: dict = Depends(get_current_encargado)) -> PedidoSchema:

    if not carga.pedidoId:
        raise HTTPException(status_code=400, detail="Una carga debe estar asociada a un pedidoId")

    company_id = current_user.get("companyId")
    pedido_doc = db.collection("pedidos").document(carga.pedidoId).get()
    
    if not pedido_doc.exists:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")

    return PedidoSchema.from_firestore(pedido_doc, company_id)