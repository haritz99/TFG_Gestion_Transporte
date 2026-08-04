from typing import Any
from fastapi import APIRouter, Depends, Query, status

from ..dependencies.auth import get_current_encargado
from ..schemas import VehiculoSchema, VehiculoPaginatedSchema
from ..services.vehiculo_service import VehiculoService

router = APIRouter(prefix="/vehi", tags=["vehiculos"], dependencies=[Depends(get_current_encargado)])


@router.get("", response_model=VehiculoPaginatedSchema)
def get_vehiculos(
    limit: int = 8,
    lastDocId: str = Query(None),
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(VehiculoService),
):
    company_id = current_user.get("companyId")
    return service.get_all(company_id, limit=limit, last_doc_id=lastDocId)


@router.get("/{matr}", response_model=VehiculoSchema)
def get_vehiculo(
    matr: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(VehiculoService),
):
    company_id = current_user.get("companyId")
    return service.get_by_id(matr.upper(), company_id)


@router.post("", response_model=VehiculoSchema, status_code=status.HTTP_201_CREATED)
def create_vehiculo(
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(VehiculoService),
):
    company_id = current_user.get("companyId")
    return service.create(vehiculo_data, company_id)


@router.put("/{matr}", response_model=VehiculoSchema)
def update_vehiculo(
    matr: str,
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(VehiculoService),
):
    company_id = current_user.get("companyId")
    return service.update(matr.upper(), vehiculo_data, company_id)


@router.delete("/{matr}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vehiculo(
    matr: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: VehiculoService = Depends(VehiculoService),
):
    company_id = current_user.get("companyId")
    service.delete(matr.upper(), company_id)
    return None
