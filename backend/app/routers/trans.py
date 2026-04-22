from fastapi import APIRouter, Depends
from typing import Any
from ..schemas.users import UserSchema, UserCountSchema, UserPaginatedSchema, UserCreateResponseSchema
from ..dependencies.auth import get_current_encargado
from ..services.trans_service import TransService, get_trans_service

router = APIRouter(prefix="/trans", tags=["trans"], dependencies=[Depends(get_current_encargado)])

@router.get("/", response_model=UserPaginatedSchema)
async def get_all_trans(
        solodis: bool = False,
        limit: int = 8,
        last_doc_id: str | None = None,
        current_user: dict[str, Any] = Depends(get_current_encargado),
        service: TransService = Depends(get_trans_service)):

    company_id = current_user.get("companyId")
    response = service.get_all_trans(
        company_id=company_id,
        solodis=solodis,
        limit=limit,
        last_doc_id=last_doc_id
    )
    return response

@router.get("/count", response_model=UserCountSchema)
async def get_count_trans(
        current_user: dict[str, Any] = Depends(get_current_encargado),
        service: TransService = Depends(get_trans_service)):

    company_id = current_user.get("companyId")
    return service.get_count_trans(company_id=company_id)

@router.get("/{uid}")
async def get_trans(uid: str, current_user: dict[str, Any] = Depends(get_current_encargado),
                    service: TransService = Depends(get_trans_service)):

    company_id = current_user.get("companyId")
    return service.get_trans(uid=uid, company_id=company_id)

@router.post("/", response_model=UserCreateResponseSchema)
async def create_trans(
    user_data: UserSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: TransService = Depends(get_trans_service)
):
    company_id = current_user.get("companyId")
    return service.create_trans(user_data=user_data, company_id=company_id)

@router.put("/{uid}", response_model=UserSchema)
async def update_trans(
    uid: str,
    user_data: UserSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: TransService = Depends(get_trans_service)
):
    company_id = current_user.get("companyId")
    return service.update_trans(uid=uid, user_data=user_data, company_id=company_id)

@router.delete("/{uid}")
async def delete_trans(uid: str, current_user: dict[str, Any] = Depends(get_current_encargado),
                       service: TransService = Depends(get_trans_service)):
    company_id = current_user.get("companyId")
    return service.delete_trans(uid=uid, company_id=company_id)
