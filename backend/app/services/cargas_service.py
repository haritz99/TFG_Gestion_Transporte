import datetime
import pytz
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


def calculate_asignados(company_id: str):
    ca_result = (db.collection('cargas')
                 .where('companyId', '==', company_id)
                 .where('estado', '==', EstadoCarga.ASIGNADO.value)
                 .count()
                 .get())
    cargas_asignadas = ca_result[0][0].value
    return cargas_asignadas

def calculate_sin_asignar(company_id: str):
    csa_result = (db.collection('cargas')
                  .where('companyId', '==', company_id)
                  .where('estado', '==', EstadoCarga.PENDIENTE.value)
                  .count()
                  .get())
    cargas_sin_asignar = csa_result[0][0].value
    return cargas_sin_asignar

def calculate_cargas_hoy(company_id: str, sod: datetime.datetime, eod: datetime.datetime, estado: Optional[EstadoCarga] = None):
    # Esto se hace para comparar la fecha en firestore
    if sod.tzinfo is None:
        sod = pytz.utc.localize(sod)
    if eod.tzinfo is None:
        eod = pytz.utc.localize(eod)
    print("Hasta aqui todo bien")
    query = (db.collection('cargas')
             .where('companyId', '==', company_id)
             .where('fechaDescarga', '>=', sod)
             .where('fechaDescarga', '<=', eod)
             .order_by('fechaDescarga'))

    print("El primer query bien")
    if estado:
        query = query.where('estado', '==', estado.value)
    print("El segudno quuery bien")
    print(query)
    result = query.count().get()
    print("Devuelve bien")
    return result[0][0].value

