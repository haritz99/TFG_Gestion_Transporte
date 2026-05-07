from __future__ import annotations

from typing import Any
from fastapi import APIRouter, Depends, status
from ..schemas.external_user import ExternalUserSchema
from ..schemas.users import UserCreateResponseSchema
from ..services.external_user_service import ExternalUserService
from ..services.register_service import RegisterService
from ..dependencies.auth import get_current_encargado, get_current_user

router = APIRouter(prefix="/ext", tags=["external_users"])

@router.post("/", response_model=UserCreateResponseSchema[ExternalUserSchema])
def create_external_user(
    user_data: ExternalUserSchema,
    rol: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: RegisterService = Depends(RegisterService),
) -> UserCreateResponseSchema[ExternalUserSchema]:
    company_id = current_user.get("companyId")
    return service.create_external_user(user_data=user_data, company_id=company_id, rol=rol)

@router.get("/", response_model=list[ExternalUserSchema])
def fetch_external_users(
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: ExternalUserService = Depends(ExternalUserService),
) -> list[ExternalUserSchema]:
    """
    Obtiene la lista de todos los colaboradores (clientes y subcontratados).
    """
    company_id = current_user.get("companyId")
    return service.fetch_external_users(company_id=company_id)

"""
@router.get("/cli", response_model=list[ClienteSchema])
def get_clientes(current_user: dict[str, Any] = Depends(get_current_encargado)):
    company_id = current_user.get("companyId")
    clientes_ref = db.collection("clientes")
    query = (
        clientes_ref
        .where("companyId", "==", company_id)
        .stream()
    )

    clientes = []
    for doc in query:
        clientes.append(ClienteSchema.from_firestore(doc, company_id))

    return clientes
"""

@router.put("/profile/{uid}", response_model=ExternalUserSchema)
def update_external_user_profile(
    uid: str,
    payload: dict,
    current_user: dict[str, Any] = Depends(get_current_user),
    service: RegisterService = Depends(RegisterService)
):
    return service.update_external_user_profile(uid, payload, current_user)



@router.delete("/cli/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_cliente(
    cliente_id: str, 
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service = Depends(ExternalUserService)
):
    return service.delete_cliente_cascada(cliente_id, current_user.get("companyId"))
