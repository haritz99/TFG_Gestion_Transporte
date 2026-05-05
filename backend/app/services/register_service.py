from fastapi import HTTPException, Depends
import secrets
import string
from datetime import datetime, timezone

from ..crud.user_crud import UserCRUD
from ..schemas.users import UserSchema, UserCreateResponseSchema
from ..schemas.external_user import ExternalUserSchema
from firebase_admin import auth as firebase_auth


class RegisterService:
    def __init__(self, crud: UserCRUD = Depends(UserCRUD)):
        self._crud = crud

    @staticmethod
    def generate_temp_password(length: int = 12) -> str:
        characters = string.ascii_letters + string.digits + "!@#$%^&*"
        return ''.join(secrets.choice(characters) for _ in range(length))

    def create_firebase_auth_user(self, email: str, rol: list[str], company_id: str) -> tuple[str, str, str | None]:
        temp_password = self.generate_temp_password()
        new_auth_user = firebase_auth.create_user(email=email, password=temp_password)
        uid = new_auth_user.uid

        firebase_auth.set_custom_user_claims(uid, {"rol": rol, "companyId": company_id})

        try:
            reset_link = firebase_auth.generate_password_reset_link(email)
        except Exception:
            reset_link = None

        return uid, temp_password, reset_link

    def create_trans(self, user_data: UserSchema, company_id: str) -> UserCreateResponseSchema:
        uid = None
        try:
            uid, temp_password, reset_link = self.create_firebase_auth_user(
                email=user_data.email,
                rol=["transportista"],
                company_id=company_id,
            )

            now = datetime.now(timezone.utc)

            user_dict = user_data.model_dump()
            user_dict['uid'] = uid
            if "transportista" not in user_dict.get("rol", []):
                user_dict["rol"] = ["transportista"]
            user_dict["companyId"] = company_id
            user_dict["createdAt"] = now
            user_dict["updatedAt"] = now

            self._crud.create(uid, user_dict)

            created_user = UserSchema(**user_dict)

            return UserCreateResponseSchema(
                user=created_user,
                temp_password=temp_password,
                password_reset_link=reset_link
            )
        except firebase_auth.EmailAlreadyExistsError:
            raise HTTPException(status_code=400, detail="El email ya está registrado en el sistema")
        except Exception:
            if uid is not None:
                try:
                    firebase_auth.delete_user(uid)
                except Exception:
                    pass
            raise HTTPException(status_code=500, detail="Error interno del servidor")

    def create_external_user(self, user_data: ExternalUserSchema, company_id: str, rol: str) -> UserCreateResponseSchema[ExternalUserSchema]:
        """
        Crea un usuario externo (cliente o subcontratado) con datos iniciales.
        """
        uid = None
        try:
            uid, temp_password, reset_link = self.create_firebase_auth_user(
                email=user_data.email,
                rol=[rol],
                company_id=company_id,
            )

            now = datetime.now(timezone.utc)
            user_dict = user_data.model_dump(exclude_unset=True)
            user_dict["uid"] = uid
            user_dict["rol"] = [rol]
            user_dict["companyId"] = company_id
            user_dict["datosCompletos"] = False
            user_dict["createdAt"] = now
            user_dict["updatedAt"] = now

            if rol == "cliente":
                self._crud.create_cliente(uid, user_dict)
            elif rol == "subcontratado":
                self._crud.create_subcontratado(uid, user_dict)
            else:
                raise ValueError(f"Rol no válido para usuario externo: {rol}")

            created_user = ExternalUserSchema(**user_dict)

            return UserCreateResponseSchema(
                user=created_user,
                temp_password=temp_password,
                password_reset_link=reset_link,
            )
        except firebase_auth.EmailAlreadyExistsError:
            raise HTTPException(status_code=400, detail="El email ya está registrado en el sistema")
        except Exception as e:
            if uid is not None:
                try:
                    firebase_auth.delete_user(uid)
                except Exception:
                    pass
            if isinstance(e, HTTPException):
                raise e
            raise HTTPException(status_code=500, detail=f"Error interno del servidor: {str(e)}")

def get_register_service() -> RegisterService:
    return RegisterService()
