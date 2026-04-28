from fastapi import HTTPException
import secrets
import string
from datetime import datetime, timezone

from ..crud.user_crud import UserCRUD
from ..schemas.users import UserSchema, UserCreateResponseSchema
from ..schemas.external_user import ClienteSchema, SubcontratadoSchema
from firebase_admin import auth as firebase_auth


class RegisterService:
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

            UserCRUD.create(uid, user_dict)

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

    def create_cliente(self, cliente_data: ClienteSchema, company_id: str) -> UserCreateResponseSchema[ClienteSchema]:
        uid = None
        try:
            uid, temp_password, reset_link = self.create_firebase_auth_user(
                email=cliente_data.email,
                rol=["cliente"],
                company_id=company_id,
            )

            now = datetime.now(timezone.utc)
            cliente_dict = cliente_data.model_dump()
            cliente_dict["uid"] = uid
            cliente_dict["companyId"] = company_id
            cliente_dict["createdAt"] = now
            cliente_dict["updatedAt"] = now

            UserCRUD.create_cliente(uid, cliente_dict)
            created_cliente = ClienteSchema(**cliente_dict)

            return UserCreateResponseSchema(
                user=created_cliente,
                temp_password=temp_password,
                password_reset_link=reset_link,
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

    def create_subcontratado(self, subcontratado_data: SubcontratadoSchema, company_id: str) -> UserCreateResponseSchema[SubcontratadoSchema]:
        uid = None
        try:
            uid, temp_password, reset_link = self.create_firebase_auth_user(
                email=subcontratado_data.email,
                rol=["subcontratado"],
                company_id=company_id,
            )
            now = datetime.now(timezone.utc)
            subcontratado_dict = subcontratado_data.model_dump()
            subcontratado_dict["uid"] = uid
            subcontratado_dict["companyId"] = company_id
            subcontratado_dict["createdAt"] = now
            subcontratado_dict["updatedAt"] = now

            UserCRUD.create_subcontratado(uid, subcontratado_dict)
            created_subcontratado = SubcontratadoSchema(**subcontratado_dict)

            return UserCreateResponseSchema(
                user=created_subcontratado,
                temp_password=temp_password,
                password_reset_link=reset_link,
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

def get_register_service() -> RegisterService:
    return RegisterService()