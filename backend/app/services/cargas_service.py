import datetime
from typing import Optional, List

from ..firebase_config import db
from ..schemas.carga import CargaSchema, EstadoCarga

def fetch_cargas(
        company_id: str, 
        cliente_id: Optional[str] = None,
        pedido_id: Optional[str] = None,
        transportista_id: Optional[str] = None,
        estado: Optional[EstadoCarga] = None,
        fecha_inicio: Optional[datetime.date] = None,
        fecha_fin: Optional[datetime.date] = None) -> List[CargaSchema]:
    
    query = db.collection("cargas").where("companyId", "==", company_id)
    
    if cliente_id:
        query = query.where("clienteId", "==", cliente_id)
    if pedido_id:
        query = query.where("pedidoId", "==", pedido_id)
    if transportista_id:
        query = query.where("transportistaId", "==", transportista_id)
    if estado:
        query = query.where("estado", "==", estado.value)
        
    if fecha_inicio:
        dt_inicio = datetime.datetime.combine(fecha_inicio, datetime.time.min)
        query = query.where("fechaCarga", ">=", dt_inicio)
    if fecha_fin:
        dt_fin = datetime.datetime.combine(fecha_fin, datetime.time.max)
        query = query.where("fechaCarga", "<=", dt_fin)
        
    cargas = []
    for doc in query.stream():
        cargas.append(CargaSchema.from_firestore(doc, company_id))
        
    return cargas

