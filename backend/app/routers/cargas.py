from __future__ import annotations

import datetime
from typing import Any, Optional
from fastapi import APIRouter, Depends, Query, status
from ..dependencies.auth import get_current_encargado, get_current_sub, get_current_conductor, \
    get_current_encargado_cargador
from ..dependencies.services import get_carta_porte_service
from ..interfaces.i_carta_porte_service import ICartaPorteService
from ..schemas import IncidenciaSchema
from ..schemas.carga import CargaSchema, EstadoCarga, TipoCargaSchema, CargaUpdateSubSchema
from ..services.cargas_service import CargasService
from ..services.incidencias_service import IncidenciaService

router = APIRouter(prefix="/cargas", tags=["cargas"])

@router.get("", response_model=list[CargaSchema])
def get_cargas(
    cliente_id: Optional[str] = Query(None, description="Filtrar por ID de cliente"),
    pedido_id: Optional[str] = Query(None, description="Filtrar por ID de pedido"),
    transportista_id: Optional[str] = Query(None, description="Filtrar por ID de transportista"),
    estado: Optional[EstadoCarga] = Query(None, description="Filtrar por estado"),
    fecha_inicio: Optional[datetime.date] = Query(None, description="Fecha inicio de carga (YYYY-MM-DD)"),
    fecha_fin: Optional[datetime.date] = Query(None, description="Fecha límite de carga (YYYY-MM-DD)"),
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: CargasService = Depends(CargasService)
):
    return service.fetch_cargas(
        company_id=current_user.get("companyId"),
        cliente_id=cliente_id,
        pedido_id=pedido_id,
        transportista_id=transportista_id,
        estado=estado,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )

@router.get("/tipos", response_model=list[TipoCargaSchema])
def get_tipos_carga(
        cliente_id: str,
        current_user: dict[str, Any] = Depends(get_current_encargado_cargador),
        service: CargasService = Depends(CargasService)):

    return service.get_tipos_carga(current_user.get("companyId"), cliente_id)

@router.post("/tipos", response_model=TipoCargaSchema, status_code=status.HTTP_201_CREATED)
def create_tipo_carga(
        tipo_carga: TipoCargaSchema,
        current_user: dict[str, Any] = Depends(get_current_encargado_cargador),
        service: CargasService = Depends(CargasService)):

    return service.create_tipo_carga(current_user.get("companyId"), tipo_carga)

@router.get("/subcontratado", response_model=list[CargaSchema])
def get_cargas_subcontratado(
    current_user: dict[str, Any] = Depends(get_current_sub),
    service: CargasService = Depends(CargasService)
):
    return service.fetch_cargas_cedidas(current_user.get("uid"))


@router.get("/{carga_id}/carta-porte")
def get_carta_porte_pdf(
    carga_id: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: ICartaPorteService = Depends(get_carta_porte_service),
) -> dict:
    url_pdf = service.generar_carta_porte_pdf(carga_id, current_user.get("companyId"))
    return {"url": url_pdf}


@router.get("/{carga_id}", response_model=CargaSchema)
def get_carga_by_id(carga_id: str,
                    current_user: dict[str, Any] = Depends(get_current_encargado),
                    service: CargasService = Depends(CargasService)) -> CargaSchema:

    return service.get_carga_by_id(carga_id, current_user.get("companyId"))


"""
@router.post("/", response_model=CargaSchema, status_code=status.HTTP_201_CREATED)
def create_carga(carga: CargaSchema,
                 pedido_schema: PedidoSchema = Depends(get_pedido_from_carga),
                 current_user: dict[str, Any] = Depends(get_current_encargado),
                 service: CargasService = Depends(CargasService)):
    return service.create_carga(carga, pedido_schema, current_user.get("companyId"))
"""


@router.put("/bulk", response_model=list[CargaSchema])
def bulk_update_cargas(
    cargas: list[CargaSchema],
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: CargasService = Depends(CargasService)
):
    return service.bulk_update_cargas(cargas, current_user.get("companyId"))

"""
@router.put("/{carga_id}", response_model=CargaSchema)
def update_carga(carga_id: str, 
                 carga: CargaSchema, 
                 pedido_schema: PedidoSchema = Depends(get_pedido_from_carga),
                 current_user: dict[str, Any] = Depends(get_current_encargado),
                 service: CargasService = Depends(CargasService)):
    return service.update_carga(carga_id, carga, pedido_schema, current_user.get("companyId"))
"""


@router.put("/{carga_id}/buffer-hours")
def update_buffer_hours(carga_id: str,
        buffer_hours: int = Query(..., ge=0, description="Horas de buffer para la carga"),
        current_user: dict[str, Any] = Depends(get_current_encargado),
        service: CargasService = Depends(CargasService)):
    return service.update_buffer_hours(carga_id, buffer_hours, current_user.get("companyId"))

@router.put("/sub/{carga_id}", response_model=CargaSchema)
def update_carga_sub(carga_id: str,
                 carga: CargaUpdateSubSchema,
                 current_user: dict[str, Any] = Depends(get_current_sub),
                 service: CargasService = Depends(CargasService)):
    return service.update_carga_sub(carga_id, carga, current_user.get("companyId"))

@router.post("/{carga_id}/subcontratar", response_model=CargaSchema)
def ceder_carga(
    carga_id: str,
    payload: dict,
    comision: float = Query(default=3.0, ge=0, le=100),
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: CargasService = Depends(CargasService),
):
    return service.ceder_carga_subcontratado(carga_id, payload.get('subcontratadoId'), current_user.get("companyId"), comision)

@router.delete("/{carga_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_carga(carga_id: str,
                 current_user: dict[str, Any] = Depends(get_current_encargado),
                 service: CargasService = Depends(CargasService)):
    service.delete_carga(carga_id, current_user.get("companyId"))
    return None


@router.patch("/{carga_id}/estado", response_model=CargaSchema)
def update_carga_estado(
    carga_id: str,
    payload: dict,
    current_user: dict[str, Any] = Depends(get_current_conductor),
    service: CargasService = Depends(CargasService)
):
    return service.update_estado_carga(carga_id, payload.get("estado"), current_user.get("companyId"))

@router.post("/{carga_id}/incidencia", response_model=dict[str, str])
def create_incidencia(
        carga_id: str,
        data: IncidenciaSchema,
        current_user: dict[str, Any] = Depends(get_current_conductor),
        service: IncidenciaService = Depends(IncidenciaService),
):
    return service.create_incidencia(carga_id, data, current_user)


@router.patch("/{carga_id}/incidencia/{incidencia_id}/resolver", response_model=dict[str, str])
def resolver_incidencia(
    carga_id: str,
    incidencia_id: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: IncidenciaService = Depends(IncidenciaService),
):
    return service.resolver_incidencia(incidencia_id)