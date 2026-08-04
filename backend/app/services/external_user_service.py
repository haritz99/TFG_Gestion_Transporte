from fastapi import Depends, HTTPException
from datetime import datetime
from firebase_admin import auth as firebase_auth
from ..schemas.external_user import ExternalUserSchema
from ..dependencies.repositories import get_user_repository
from ..interfaces.i_user_repository import IUserRepository


class ExternalUserService:
    def __init__(self, user_crud: IUserRepository = Depends(get_user_repository)):
        self._user_crud = user_crud

    def fetch_external_users(self, company_id: str) -> list[ExternalUserSchema]:
        """
        Obtiene todos los usuarios externos que esten activos, se usa en la lista de Invite.
        """
        docs = self._user_crud.get_all_external_users(company_id)
        users = []
        for doc in docs:
            data = doc.to_dict()
            if not data:
                continue
            data["uid"] = doc.id
            users.append(ExternalUserSchema(**data))

        users.sort(key=lambda x: x.createdAt or datetime.min, reverse=True)
        return users

    def soft_delete_external_user(self, uid: str, company_id: str):
        """
        Realiza un soft delete de un usuario externo (cliente o subcontratado).
        """
        cliente_doc = self._user_crud.get_cliente_by_id(company_id, uid)
        sub_doc = self._user_crud.get_subcontratado_by_id(company_id, uid)

        if cliente_doc.exists:
            self._user_crud.update_cliente(company_id, uid, {"activo": False, "updatedAt": datetime.now()})
            try:
                firebase_auth.update_user(uid, disabled=True)
            except Exception:
                pass
            return

        if sub_doc.exists:
            self._user_crud.update_subcontratado(company_id, uid, {"activo": False, "updatedAt": datetime.now()})
            try:
                firebase_auth.update_user(uid, disabled=True)
            except Exception:
                pass
            return

        raise HTTPException(status_code=404, detail="Usuario no encontrado")