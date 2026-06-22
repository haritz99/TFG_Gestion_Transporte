from __future__ import annotations
from fastapi import HTTPException, Depends, status, BackgroundTasks
from typing import Any
import secrets
import string
from datetime import datetime, timezone

from .email_service import EmailService
from ..crud.user_crud import UserCRUD
from ..crud.company_crud import CompanyCRUD
from ..dependencies.auth import normalize_roles
from ..schemas.users import UserSchema, UserCreateResponseSchema, RegisterRequest
from ..schemas.external_user import ExternalUserSchema
from firebase_admin import auth as firebase_auth


class RegisterService:
    def __init__(self, email_service: EmailService = Depends(EmailService), crud: UserCRUD = Depends(UserCRUD), company_crud: CompanyCRUD = Depends(CompanyCRUD)):
        self._email_service = email_service
        self._crud = crud
        self._company_crud = company_crud

    def get_company_info(self, company_id: str) -> dict:
        if not company_id:
            raise HTTPException(status_code=400, detail="companyId es obligatorio en el token")

        try:
            company_doc = self._company_crud.get_by_id(company_id)
            if not company_doc.exists:
                raise HTTPException(status_code=404, detail="Empresa no encontrada")
            return company_doc.to_dict()
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error al obtener la información de la empresa: {str(e)}")

    def update_buffer_hours(self, company_id: str, buffer_hours: int):
        if buffer_hours < 0:
            raise HTTPException(status_code=400, detail="bufferHours debe ser un número entero no negativo")

        try:
            self._company_crud.update(company_id, {"bufferHours": buffer_hours})
            return {"message": "Buffer hours actualizadas correctamente"}
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error al actualizar buffer hours: {str(e)}")

    @staticmethod
    def generate_temp_password(length: int = 12) -> str:
        characters = string.ascii_letters + string.digits + "!@#$%^&*"
        return ''.join(secrets.choice(characters) for _ in range(length))

    def generate_reset_link(self, email: str) -> str:
        try:
            return firebase_auth.generate_password_reset_link(email)
        except firebase_auth.UserNotFoundError:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error al generar el enlace: {str(e)}")

    def create_firestore_user_with_company(self, current_user: dict, register_data: RegisterRequest) -> dict:
        uid = current_user['uid']
        now = datetime.now(timezone.utc)
        try:
            company_data = {
                'nombre': register_data.empresa.nombre,
                'razonSocial': register_data.empresa.razon_social,
                'nif': register_data.empresa.nif,
                'telefono': register_data.empresa.telefono,
                'numAutorizacion': register_data.empresa.num_autorizacion,
                'direccion': register_data.empresa.direccion.model_dump() if register_data.empresa.direccion else None,
                'createdAt': now,
            }
            company_id = self._company_crud.create(company_data)

            user_dict = {
                'uid': uid,
                'nombre': register_data.nombre,
                'apellido': register_data.apellido,
                'email': register_data.email,
                'telefono': register_data.telefono,
                'rol': register_data.rol,
                'permisosCond': register_data.permisos_cond,
                'companyId': company_id,
                'estado': register_data.estado or 'sin_asignar',
                'vehiculoId': None,
                'createdAt': now,
                'updatedAt': now,
            }
            self._crud.create(uid, user_dict)

            firebase_auth.set_custom_user_claims(uid, {
                'companyId': company_id,
                'rol': register_data.rol,
            })

            return {'companyId': company_id}

        except Exception as e:
            try:
                firebase_auth.delete_user(uid)
            except Exception:
                pass
            raise HTTPException(status_code=500, detail=str(e))

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

    def create_trans(self, user_data: UserSchema, company_id: str, background_tasks: BackgroundTasks) -> UserCreateResponseSchema:
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

            background_tasks.add_task(
                self._email_service.send_welcome_email,
                email=user_data.email,
                temp_password=temp_password,
                reset_link=reset_link
            )

            return UserCreateResponseSchema(
                user=created_user,
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

    def create_external_user(self, user_data: ExternalUserSchema, company_id: str, rol: str, background_tasks: BackgroundTasks) -> UserCreateResponseSchema[ExternalUserSchema]:
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

            background_tasks.add_task(
                self._email_service.send_welcome_email,
                email=user_data.email,
                temp_password=temp_password,
                reset_link=reset_link
            )

            return UserCreateResponseSchema(
                user=created_user,
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

    def update_external_user_profile(self, uid: str, data: dict, current_user: dict[str, Any]):
        """
        Actualiza el perfil de un usuario externo la primera vez que entra en la app (cliente o subcontratado).
        """
        if current_user.get("uid") != uid:
            raise HTTPException(status_code=403, detail="No autorizado para actualizar este perfil")

        company_id = current_user.get("companyId")
        if not company_id:
            raise HTTPException(status_code=400, detail="companyId es obligatorio en el token")

        try:
            roles = current_user.get("rol", [])
            rol = roles[0] if roles else None

            if rol not in ["cliente", "subcontratado"]:
                raise HTTPException(status_code=400, detail="Rol no válido para usuario externo")

            doc_data = {}

            data['datosCompletos'] = True
            data['activo'] = True
            data['updatedAt'] = datetime.now(timezone.utc)
            data['companyId'] = company_id

            if rol == "cliente":
                doc = self._crud.get_cliente_by_id(uid)
                doc_data = doc.to_dict() or {}
                self._crud.update_cliente(uid, data)
            elif rol == "subcontratado":
                doc = self._crud.get_subcontratado_by_id(uid)
                doc_data = doc.to_dict() or {}
                self._crud.update_subcontratado(uid, data)

            full_data = {**doc_data, **data}
            return ExternalUserSchema(**full_data)
        except Exception:
            raise HTTPException(status_code=500, detail="Error interno del servidor")


    # Funcion de custom_claims para los usuarios cuando se registran
    def initialize_custom_claims(self, current_user, company_id, rol):
        uid = current_user.get("uid")
        if not isinstance(uid, str) or not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token sin uid válido",
            )

        company_id = company_id.strip()
        roles = normalize_roles(rol)

        claims = {"rol": roles, "companyId": company_id}

        try:
            auth_user = firebase_auth.get_user(uid)
            current_claims = auth_user.custom_claims or {}

            if current_claims:
                current_roles = normalize_roles(current_claims.get("rol"))
                current_company_id = current_claims.get("companyId")

                if current_company_id == company_id and current_roles == roles:
                    return {
                        "message": "Los custom claims ya estaban inicializados.",
                        "uid": uid,
                        "claims": claims,
                    }

                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="El usuario ya tiene claims asignados con valores diferentes.",
                )

            firebase_auth.set_custom_user_claims(uid, claims)
            return {
                "message": "Custom claims inicializados correctamente.",
                "uid": uid,
                "claims": claims,
            }
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="No se pudieron inicializar los custom claims",
            )

def get_register_service() -> RegisterService:
    return RegisterService()
