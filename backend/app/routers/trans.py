from fastapi import APIRouter, Depends, Query, BackgroundTasks
from typing import Any
from ..dependencies.auth import get_current_encargado
from ..schemas.users import UserSchema, UserPaginatedSchema, UserCreateResponseSchema
from ..services.register_service import RegisterService
from ..services.trans_service import TransService

router = APIRouter(prefix="/trans", tags=["trans"], dependencies=[Depends(get_current_encargado)])

@router.get("", response_model=UserPaginatedSchema)
def get_all_trans(
    limit: int = 8,
    lastDocId: str = Query(None),
    solodis : bool = Query(False),
    current_user: dict[str, Any] = Depends(get_current_encargado),
    trans_service: TransService = Depends(TransService)
):
    company_id = current_user.get("companyId")
    return trans_service.get_all_trans(company_id, solodis=solodis, limit=limit, last_doc_id=lastDocId)

@router.get("/{uid}", response_model=UserSchema)
def get_trans_by_uid(
    uid: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    trans_service: TransService = Depends(TransService)
):
    company_id = current_user.get("companyId")
    user_data = trans_service.get_trans(uid, company_id)
    return UserSchema(**user_data)

@router.post("", response_model=UserCreateResponseSchema)
def create_trans(
    user_data: UserSchema,
    background_tasks: BackgroundTasks,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    register_service: RegisterService = Depends(RegisterService)
):
    return register_service.create_trans(user_data, current_user.get("companyId"), background_tasks)

@router.put("/{uid}", response_model=UserSchema)
def update_trans(
    uid: str,
    user_data: UserSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    trans_service: TransService = Depends(TransService)
):
    company_id = current_user.get("companyId")
    return trans_service.update_trans(uid, user_data, company_id)


@router.delete("/{uid}", status_code=204)
def delete_trans(
    uid: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    trans_service: TransService = Depends(TransService)
):
    company_id = current_user.get("companyId")
    trans_service.delete_trans(uid, company_id)
    return None
