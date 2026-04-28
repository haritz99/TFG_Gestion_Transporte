from typing import Any, Dict
from fastapi import HTTPException
from firebase_admin import auth as firebase_auth
from ..schemas.users import UserSchema, UserCountSchema, UserPaginatedSchema
from ..crud.trans_crud import TransCRUD
from ..crud.user_crud import UserCRUD

class TransService:
    def get_all_trans(self, company_id: str, solodis: bool, limit: int, last_doc_id: str | None = None) -> UserPaginatedSchema:
        query = TransCRUD.get_all(company_id, solodis, limit=limit+1, last_doc_id=last_doc_id)
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
        doc = UserCRUD.get_by_id(uid)

        if not doc.exists:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        user_data = doc.to_dict() or {}
        if user_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        rol = user_data.get("rol", [])
        if isinstance(rol, str):
            rol = [rol]
        if "transportista" not in rol:
            raise HTTPException(status_code=400, detail="El usuario indicado no es transportista")

        user_data["uid"] = doc.id
        return user_data

    def get_count_trans(self, company_id: str) -> UserCountSchema:
        try:
            total_res = TransCRUD.get_count(company_id)
            # En algunas versiones de Firestore se devuelve una lista dentro de otra lista, esto acepta ambos casos
            total = total_res[0][0].value if isinstance(total_res[0], list) else total_res[0].value

            asignados_res = TransCRUD.get_count_by_estado(company_id, "asignado")
            asignados = asignados_res[0][0].value if isinstance(asignados_res[0], list) else asignados_res[0].value

            sin_asignar_res = TransCRUD.get_count_by_estado(company_id, "sin_asignar")
            sin_asignar = sin_asignar_res[0][0].value if isinstance(sin_asignar_res[0], list) else sin_asignar_res[0].value

            parcial_res = TransCRUD.get_count_by_estado(company_id, "asignacion_parcial")
            parcial = parcial_res[0][0].value if isinstance(parcial_res[0], list) else parcial_res[0].value

            en_ruta_res = TransCRUD.get_count_by_estado(company_id, "en_ruta")
            en_ruta = en_ruta_res[0][0].value if isinstance(en_ruta_res[0], list) else en_ruta_res[0].value

            inactivos_res = TransCRUD.get_count_by_estado(company_id, "inactivo")
            inactivos = inactivos_res[0][0].value if isinstance(inactivos_res[0], list) else inactivos_res[0].value

            return UserCountSchema(
                total_trans=total,
                sin_asignar=sin_asignar,
                asignacion_parcial=parcial,
                en_ruta=en_ruta,
                inactivos=inactivos
            )

        except Exception as e:
            print(f"Error en get_count: {e}")
            raise HTTPException(status_code=500, detail=f"Error al contar los transportistas: {str(e)}")

    def update_trans(self, uid: str, user_data: UserSchema, company_id: str) -> UserSchema:
        doc = UserCRUD.get_by_id(uid)

        if not doc.exists:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        doc_data = doc.to_dict() or {}
        if doc_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        rol = doc_data.get("rol", [])
        if isinstance(rol, str):
            rol = [rol]
        if "transportista" not in rol:
            raise HTTPException(status_code=400, detail="El usuario indicado no es transportista")

        update_data = user_data.model_dump(exclude_unset=True)
        update_data.pop("companyId", None)
        update_data.pop("rol", None)

        from datetime import datetime, timezone
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
                    detail="No se encontró la cuenta de autenticación asociada al transportista"
                )
            except Exception as e:
                raise HTTPException(status_code=400, detail=str(e))

        UserCRUD.update(uid, update_data)
        full_data = {**doc_data, **update_data, "uid": uid}
        updated_user = UserSchema(**full_data)
        return updated_user

    def delete_trans(self, uid: str, company_id: str) -> Dict[str, str]:
        try:
            doc = UserCRUD.get_by_id(uid)
            if not doc.exists:
                raise HTTPException(status_code=404, detail="Transportista no encontrado")

            doc_data = doc.to_dict() or {}
            if doc_data.get("companyId") != company_id:
                raise HTTPException(status_code=404, detail="Transportista no encontrado")

            rol = doc_data.get("rol", [])
            if isinstance(rol, str):
                rol = [rol]
            if "transportista" not in rol:
                raise HTTPException(status_code=400, detail="El usuario indicado no es transportista")

            vehiculo_id = doc_data.get("vehiculoId")
            if vehiculo_id is not None:
                vehiculo_doc = TransCRUD.get_vehiculo(vehiculo_id)
                if vehiculo_doc.exists:
                    TransCRUD.update_vehiculo(vehiculo_id, {"transportistaId": None})

            try:
                firebase_auth.delete_user(uid)
            except firebase_auth.UserNotFoundError:
                pass

            UserCRUD.delete(uid)

            if vehiculo_id is not None:
                return {"message": "Transportista eliminado con éxito y vehículo liberado"}

            return {"message": "Transportista eliminado con éxito"}
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error interno del servidor")

def get_trans_service() -> TransService:
    return TransService()
