from typing import Any, Dict
from fastapi import HTTPException, Depends
from datetime import datetime, timezone
from firebase_admin import auth as firebase_auth
from ..schemas.users import UserSchema, UserPaginatedSchema
from ..crud.trans_crud import TransCRUD
from ..crud.user_crud import UserCRUD

class TransService:
    def __init__(self, crud: TransCRUD = Depends(TransCRUD), user_crud: UserCRUD = Depends(UserCRUD)):
        self._crud = crud
        self._user_crud = user_crud

    def get_all_trans(self, company_id: str, solodis: bool, limit: int, last_doc_id: str | None = None) -> UserPaginatedSchema:
        query = self._crud.get_all(company_id, solodis, limit=limit+1, last_doc_id=last_doc_id, user_crud=self._user_crud)
        docs = list(query)
        has_more = len(docs) > limit
        if has_more:
            docs = docs[:-1]

        transportistas = []

        for doc in docs:
            user = UserSchema.from_firestore(doc, company_id)
            transportistas.append(user)

        last_id = docs[-1].id if docs else None

        return UserPaginatedSchema(
            items=transportistas,
            last_doc_id=last_id,
            has_more=has_more
        )

    def get_trans(self, uid: str, company_id: str) -> Dict[str, Any]:
        doc = self._user_crud.get_by_id(uid)

        if not doc.exists:
            raise HTTPException(status_code=404, detail="Conductor no encontrado")

        user_data = doc.to_dict() or {}
        if user_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Conductor no encontrado")

        rol = user_data.get("rol", [])
        if isinstance(rol, str):
            rol = [rol]
        if "transportista" not in rol:
            raise HTTPException(status_code=400, detail="El usuario indicado no es transportista")

        user_data["uid"] = doc.id
        return user_data

    def update_trans(self, uid: str, user_data: UserSchema, company_id: str) -> UserSchema:
        doc = self._user_crud.get_by_id(uid)

        if not doc.exists:
            raise HTTPException(status_code=404, detail="Conductor no encontrado")

        doc_data = doc.to_dict() or {}
        if doc_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Conductor no encontrado")

        rol = doc_data.get("rol", [])
        if isinstance(rol, str):
            rol = [rol]
        if "transportista" not in rol:
            raise HTTPException(status_code=400, detail="El usuario indicado no es conductor")

        update_data = user_data.model_dump(exclude_unset=True)
        update_data.pop("companyId", None)
        update_data.pop("rol", None)
        update_data["updatedAt"] = datetime.now(timezone.utc)

        new_email = update_data.get("email")
        old_email = doc_data.get("email")
        if new_email is not None and new_email != old_email:
            try:
                firebase_auth.update_user(uid, email=new_email)
            except firebase_auth.EmailAlreadyExistsError:
                raise HTTPException(
                    status_code=400,
                    detail="El email proporcionado ya está en uso en otra cuenta"
                )
            except firebase_auth.UserNotFoundError:
                raise HTTPException(
                    status_code=400,
                    detail="No se encontró la cuenta de autenticación asociada al conductor"
                )
            except Exception as e:
                raise HTTPException(status_code=400, detail=str(e))

        self._user_crud.update(uid, update_data)
        full_data = {**doc_data, **update_data, "uid": uid}
        updated_user = UserSchema(**full_data)
        return updated_user

    def delete_trans(self, uid: str, company_id: str) -> Dict[str, str]:
        try:
            doc = self._user_crud.get_by_id(uid)
            if not doc.exists:
                raise HTTPException(status_code=404, detail="Conductor no encontrado")

            doc_data = doc.to_dict() or {}
            if doc_data.get("companyId") != company_id:
                raise HTTPException(status_code=404, detail="Conductor no encontrado")

            rol = doc_data.get("rol", [])
            if isinstance(rol, str):
                rol = [rol]
            if "transportista" not in rol:
                raise HTTPException(status_code=400, detail="El usuario indicado no es condcutor")

            try:
                firebase_auth.delete_user(uid)
            except firebase_auth.UserNotFoundError:
                pass

            self._user_crud.delete(uid)

            return {"message": "Conductor eliminado con éxito"}
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error interno del servidor")
