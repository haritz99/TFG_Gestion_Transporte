from __future__ import annotations

from typing import Any
from fastapi import APIRouter, Depends, status, BackgroundTasks, Body
from ..schemas.external_user import ExternalUserSchema
from ..schemas.users import UserCreateResponseSchema
from ..services.email_service import EmailService
from ..services.external_user_service import ExternalUserService
from ..services.register_service import RegisterService
from ..dependencies.auth import get_current_encargado, get_current_user

router = APIRouter(prefix="/ext", tags=["external_users"])

@router.post("", response_model=UserCreateResponseSchema[ExternalUserSchema])
def create_external_user(
    user_data: ExternalUserSchema,
    rol: str,
    background_tasks: BackgroundTasks,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: RegisterService = Depends(RegisterService),
) -> UserCreateResponseSchema[ExternalUserSchema]:
    company_id = current_user.get("companyId")
    return service.create_external_user(user_data=user_data, company_id=company_id, rol=rol, background_tasks=background_tasks)

@router.post("/invite", response_model=dict[str, str])
def invite_external_user(
    background_tasks: BackgroundTasks,
    email: str = Body(..., embed=True),
    current_user: dict[str, Any] = Depends(get_current_encargado),
    register_service: RegisterService = Depends(RegisterService),
    email_service: EmailService = Depends(EmailService)
):
    temp_pass = register_service.generate_temp_password()
    reset_link = register_service.generate_reset_link(email)

    background_tasks.add_task(
        email_service.send_welcome_email,
        email=email,
        temp_password=temp_pass,
        reset_link=reset_link
    )
    return {"message": "Invitación enviada correctamente."}

@router.get("", response_model=list[ExternalUserSchema])
def fetch_external_users(
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: ExternalUserService = Depends(ExternalUserService),
) -> list[ExternalUserSchema]:
    """
    Obtiene la lista de todos los colaboradores (clientes y subcontratados).
    """
    company_id = current_user.get("companyId")
    return service.fetch_external_users(company_id=company_id)


@router.put("/profile/{uid}", response_model=ExternalUserSchema)
def update_external_user_profile(
    uid: str,
    payload: dict,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: RegisterService = Depends(RegisterService)
):
    return service.update_external_user_profile(uid, payload, current_user)



@router.delete("/{uid}", status_code=status.HTTP_204_NO_CONTENT)
def delete_external_user(
    uid: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: ExternalUserService = Depends(ExternalUserService)
):
    """
    Realiza un soft delete de un cliente o subcontratado.
    """
    return service.soft_delete_external_user(uid, current_user.get("companyId"))

@router.delete("/cli/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_cliente(
    cliente_id: str, 
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service = Depends(ExternalUserService)
):
    return service.delete_cliente_cascada(cliente_id, current_user.get("companyId"))
