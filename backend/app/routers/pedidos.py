from __future__ import annotations

import datetime
from typing import Any, Optional

from fastapi import APIRouter, Depends, Query
from ..dependencies.auth import get_current_encargado, get_current_cargador, \
    get_current_encargado_cargador
from ..schemas.pedido import PedidoSchema, CreatePedidoSchema
from ..services.pedidos_service import PedidosService

router = APIRouter(prefix="/pedidos", tags=["pedidos"])

@router.get("/", response_model=list[PedidoSchema])
def get_pedidos(
    cliente_id: Optional[str] = Query(None, description="Filtrar por ID de cliente"),
    estado: Optional[str] = Query(None, description="Filtrar por estado del pedido"),
    fecha_inicio: Optional[datetime.date] = Query(None, description="Fecha inicio de carga (YYYY-MM-DD)"),
    fecha_fin: Optional[datetime.date] = Query(None, description="Fecha límite de carga (YYYY-MM-DD)"),
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: PedidosService = Depends(PedidosService)
):
    return service.fetch_pedidos(
        company_id=current_user.get("companyId"),
        cliente_id=cliente_id,
        estado=estado,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )

@router.get("/cargador", response_model=list[PedidoSchema])
def get_pedidos_cargador_endpoint(
    current_user: dict[str, Any] = Depends(get_current_cargador),
    service: PedidosService = Depends(PedidosService)
):
    return service.fetch_pedidos(
        company_id=current_user.get("companyId"),
        cliente_id=current_user.get("uid")
    )

@router.get("/{pedido_id}", response_model=PedidoSchema)
def get_pedido_by_id(pedido_id: str,
                     current_user: dict[str, Any] = Depends(get_current_encargado),
                     service: PedidosService = Depends(PedidosService)) -> PedidoSchema:
    return service.get_pedido_by_id(pedido_id, current_user.get("companyId"))


@router.post("/", status_code=201)
def insert_pedido(pedido: CreatePedidoSchema,
                  current_user: dict[str, Any] = Depends(get_current_encargado_cargador),
                  service: PedidosService = Depends(PedidosService)):
    return service.create_pedido(pedido, current_user.get("companyId"))


@router.delete("/{pedido_id}", status_code=204)
def delete_pedido(pedido_id: str,
                  current_user: dict[str, Any] = Depends(get_current_encargado),
                  service: PedidosService = Depends(PedidosService)):
    service.delete_pedido(pedido_id, current_user.get("companyId"))
    return None
