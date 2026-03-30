import datetime
from typing import Optional, List

from ..firebase_config import db
from ..schemas.pedido import PedidoSchema

def fetch_pedidos(
        company_id: str, 
        cliente_id: Optional[str] = None, 
        estado: Optional[str] = None,
        fecha_inicio: Optional[datetime.date] = None,
        fecha_fin: Optional[datetime.date] = None) -> List[PedidoSchema]:
    
    pedidos_query = db.collection("pedidos").where("companyId", "==", company_id)
    
    if cliente_id:
        pedidos_query = pedidos_query.where("clienteId", "==", cliente_id)
    if estado:
        pedidos_query = pedidos_query.where("estado", "==", estado)
        
    if fecha_inicio:
        # Convertir a datetime al inicio del día
        dt_inicio = datetime.datetime.combine(fecha_inicio, datetime.time.min)
        pedidos_query = pedidos_query.where("fechaCarga", ">=", dt_inicio)
        
    if fecha_fin:
        # Convertir a datetime al final del día
        dt_fin = datetime.datetime.combine(fecha_fin, datetime.time.max)
        pedidos_query = pedidos_query.where("fechaCarga", "<=", dt_fin)
        
    pedidos = []
    for doc in pedidos_query.stream():
        pedidos.append(PedidoSchema.from_firestore(doc, company_id))
        
    return pedidos

