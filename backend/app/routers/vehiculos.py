from typing import Any

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from ..schemas import VehiculoPaginatedSchema, VehiculoSchema
from ..dependencies.auth import get_current_encargado
from ..schemas.vehiculos import VehiculoCountSchema
from ..services.vehiculo_service import VehiculoService, get_vehiculo_service


router = APIRouter(prefix="/vehi", tags=["vehiculos"], dependencies=[Depends(get_current_encargado)])


class VehiculoAssignSchema(BaseModel):
    matr: str = Field(..., min_length=3)
    uid: str = Field(..., min_length=1)


@router.get("/", response_model=VehiculoPaginatedSchema)
async def get_all_vehiculos(
    limit: int = 6,
    last_doc_id: str | None = None,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(get_vehiculo_service),
) -> VehiculoPaginatedSchema:
    return service.get_all(current_user["companyId"], limit, last_doc_id)

@router.get("/count", response_model=VehiculoCountSchema)
async def get_count_vehiculos(
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(get_vehiculo_service),
) -> VehiculoCountSchema:
    return service.get_count(current_user["companyId"])


@router.get("/{matr}", response_model=VehiculoSchema)
async def get_vehiculo(
    matr: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(get_vehiculo_service),
) -> VehiculoSchema:
    return service.get_by_id(matr, current_user["companyId"])


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=VehiculoSchema)
async def create_vehiculo(
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(get_vehiculo_service),
) -> VehiculoSchema:
    return service.create(vehiculo_data, current_user["companyId"])


@router.put("/{matr}", response_model=VehiculoSchema)
async def update_vehiculo(
    matr: str,
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(get_vehiculo_service),
) -> VehiculoSchema:
    return service.update(matr, vehiculo_data, current_user["companyId"])


@router.delete("/{matr}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vehiculo(
    matr: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(get_vehiculo_service),
):
    return service.delete(matr, current_user["companyId"])


@router.patch("/assign", response_model=VehiculoSchema)
async def asignar_vehiculo_a_transportista(
    data: VehiculoAssignSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(get_vehiculo_service),
) -> VehiculoSchema:
    return service.assign(data.matr, data.uid, current_user["companyId"])

