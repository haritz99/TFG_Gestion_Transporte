from __future__ import annotations

import datetime
from typing import Any, Optional, List, Dict

from fastapi import APIRouter, Depends, Query, HTTPException
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db
from ..schemas.pedido import PedidoSchema
from ..services.pedidos_service import fetch_pedidos
from ..services.cargas_service import fetch_cargas

router = APIRouter(prefix="/pedidos", tags=["pedidos"], dependencies=[Depends(get_current_encargado)])

@router.get("/", response_model=list[PedidoSchema])
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

@router.get("/{pedido_id}", response_model=PedidoSchema)
def get_pedido_by_id(pedido_id: str,
                     current_user: dict[str, Any] = Depends(get_current_encargado)) -> PedidoSchema:
    company_id = current_user.get('companyId')
    pedido_ref = db.collection("pedidos").document(pedido_id)
    pedido_doc = pedido_ref.get()

    if not pedido_doc.exists:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")

    return PedidoSchema.from_firestore(pedido_doc, company_id)


@router.post("/", status_code=201, response_model=PedidoSchema)
def insert_pedido(pedido: PedidoSchema, current_user: dict[str, Any] = Depends(get_current_encargado)):

    pedido.companyId = current_user.get("companyId")
    
    doc_ref = db.collection("pedidos").document()
    pedido.id = doc_ref.id

    nuevo_pedido_dict = pedido.model_dump()
    doc_ref.set(nuevo_pedido_dict)

    return pedido


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

    # Borrado en cascada
    # TODO: popup de confirmacion en el frontend
    cargas_asociadas = fetch_cargas(company_id=company_id, pedido_id=pedido_id)

    # Usar un batch de Firestore para que todas las eliminaciones sean atómicas
    batch = db.batch()

    for carga in cargas_asociadas:
        carga_ref = db.collection("cargas").document(carga.id)
        batch.delete(carga_ref)

    batch.delete(pedido_ref)

    try:
        batch.commit()
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Error al eliminar el pedido y sus cargas asociadas: {exc}"
        )
    return None
