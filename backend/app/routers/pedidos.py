from __future__ import annotations

import datetime
from typing import Any, Optional, List, Dict

from fastapi import APIRouter, Depends, Query ,HTTPException
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db
from ..schemas.pedido import PedidoSchema

router = APIRouter(prefix="/pedidos", tags=["pedidos"], dependencies=[Depends(get_current_encargado)])

def fetch_pedidos(
        company_id: str, 
        cliente_id: Optional[str] = None, 
        estado: Optional[str] = None,
        fecha_inicio: Optional[datetime.date] = None,
        fecha_fin: Optional[datetime.date] = None) -> List[Dict[str, Any]]:
    
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
        pedido_data = doc.to_dict()
        pedido_data["id"] = doc.id
        pedidos.append(pedido_data)
        
    return pedidos

@router.get("/")
def get_pedidos(
    cliente_id: Optional[str] = Query(None, description="Filtrar por ID de cliente"),
    estado: Optional[str] = Query(None, description="Filtrar por estado del pedido"),
    fecha_inicio: Optional[datetime.date] = Query(None, description="Fecha inicio de carga (YYYY-MM-DD)"),
    fecha_fin: Optional[datetime.date] = Query(None, description="Fecha límite de carga (YYYY-MM-DD)"),
    current_user: dict[str, Any] = Depends(get_current_encargado)
):
    return fetch_pedidos(
        company_id=current_user.get("companyId"),
        cliente_id=cliente_id,
        estado=estado,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )

@router.get("/{pedido_id}")
def get_pedido_by_id(pedido_id: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    pedido_ref = db.collection("pedidos").document(pedido_id)
    pedido_doc = pedido_ref.get()

    if not pedido_doc.exists:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")

    pedido_data = pedido_doc.to_dict()
    if pedido_data.get("companyId") != current_user.get("companyId"):
        raise HTTPException(status_code=403, detail="No autorizado para ver este pedido")

    return pedido_data


@router.post("/")
def insert_pedido(pedido: PedidoSchema, current_user: dict[str, Any] = Depends(get_current_encargado)):

    pedido.companyId = current_user.get("companyId")
    nuevo_pedido_dict = pedido.model_dump()

    doc_ref = db.collection("pedidos").document()
    nuevo_pedido_dict["id"] = doc_ref.id
    doc_ref.set(nuevo_pedido_dict)

    return nuevo_pedido_dict


@router.delete("/{pedido_id}", status_code=204)
def delete_pedido(pedido_id: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    company_id = current_user.get("companyId")
    pedido_ref = db.collection("pedidos").document(pedido_id)
    pedido_doc = pedido_ref.get()

    if not pedido_doc.exists:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")

    pedido_data = pedido_doc.to_dict()
    if pedido_data.get("companyId") != company_id:
        raise HTTPException(status_code=403, detail="No autorizado para eliminar este pedido")

    estado_actual = pedido_data.get("estado")
    if estado_actual in ["planificado", "en_progreso"]:
        raise HTTPException(
            status_code=400, 
            detail="No se puede eliminar un pedido en estado PLANIFICADO o EN_PROGRESO."
        )

    # Borrado en cascada: eliminar todas las cargas asociadas a este pedido
    # TODO: refactor y popup en el frontend
    cargas_ref = db.collection("cargas")
    cargas_query = cargas_ref.where("pedidoId", "==", pedido_id).where("companyId", "==", company_id).stream()
    
    for carga_doc in cargas_query:
        carga_doc.reference.delete()

    pedido_ref.delete()
    return None
