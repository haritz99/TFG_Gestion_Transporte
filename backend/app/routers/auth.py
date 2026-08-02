from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from ..dependencies.auth import get_current_user, get_current_encargado, get_current_encargado_conductor
from ..schemas.users import RegisterRequest
from ..services.notification_service import NotificacionService
from ..services.register_service import RegisterService

router = APIRouter(prefix="/auth", tags=["auth"])

@router.get("/company")
async def get_company_info(
    current_user: dict[str, Any] = Depends(get_current_encargado_conductor),
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


class FcmTokenSchema(BaseModel):
    token: str

@router.post("/fcm-token")
async def guardar_fcm_token(
        body: FcmTokenSchema,
        current_user: dict = Depends(get_current_user),
        service: NotificacionService = Depends(NotificacionService),
):
    service.guardar_fcm_token(
        company_id=current_user.get("companyId"),
        uid=current_user["uid"],
        roles=current_user.get("rol"),
        token=body.token,
    )
    return {"ok": True}