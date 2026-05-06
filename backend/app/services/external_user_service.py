from fastapi import Depends
from datetime import datetime
from ..schemas.external_user import ExternalUserSchema
from ..crud.user_crud import UserCRUD as userCRUD

class ExternalUserService:
    def __init__(self, crud: userCRUD = Depends(userCRUD)):
        self._crud = crud

    def fetch_external_users(self, company_id: str) -> list[ExternalUserSchema]:
        docs = self._crud.get_all_external_users(company_id)
        users = []
        for doc in docs:
            data = doc.to_dict()
            if not data:
                continue
            data["uid"] = doc.id
            users.append(ExternalUserSchema(**data))

        users.sort(key=lambda x: x.createdAt or datetime.min, reverse=True)
        return users