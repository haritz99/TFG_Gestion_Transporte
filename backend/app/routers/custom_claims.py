from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from ..dependencies.auth import get_current_user, get_current_encargado
from ..schemas.users import RegisterRequest
from ..services.register_service import RegisterService

router = APIRouter(prefix="/auth", tags=["custom-claims"])

class InitCustomClaimsRequest(BaseModel):
    companyId: str = Field(..., min_length=1)
    rol: list[str] = Field(..., min_length=1)


@router.post("/customClaims/init")
async def inicializar_custom_claims(
    payload: InitCustomClaimsRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: RegisterService = Depends(RegisterService)
):
    return service.initialize_custom_claims(current_user, payload.companyId, payload.rol)

@router.get("/company/")
async def get_company_info(
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: RegisterService = Depends(RegisterService)
):
    return service.get_company_info(current_user.get("companyId"))

@router.put("/company/{company_id}/buffer-hours")
async def update_buffer_hours(
    company_id: str,
    payload: dict,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: RegisterService = Depends(RegisterService)
):
    return service.update_buffer_hours(company_id, payload.get("bufferHours"))

@router.post("/register", status_code=201)
def register(
        data: RegisterRequest,
        current_user: dict = Depends(get_current_user),
        service: RegisterService = Depends(RegisterService)
):
    return service.create_firestore_user_with_company(current_user, data)
