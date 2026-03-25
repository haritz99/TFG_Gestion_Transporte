from fastapi import APIRouter, Depends, HTTPException
from ..schemas.users import UserSchema
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db
from firebase_admin import auth as firebase_auth
import secrets
import string

router = APIRouter(prefix="/trans", tags=["trans"], dependencies=[Depends(get_current_encargado)])


@router.get("/")
async def get_all_trans():

    users_ref = db.collection("users")

    query = users_ref.where("rol", "array_contains", "transportista").stream()
    
    transportistas = []
    for doc in query:
        user_data = doc.to_dict()
        user_data["uid"] = doc.id
        transportistas.append(user_data)
        
    return transportistas


@router.get("/{uid}")
async def get_trans(uid: str):
    doc_ref = db.collection("users").document(uid)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Transportista no encontrado")
        
    user_data = doc.to_dict()
    user_data["uid"] = doc.id
    return user_data


def generate_temp_password(length=12):
    characters = string.ascii_letters + string.digits + "!@#$%^&*"
    password = ''.join(secrets.choice(characters) for i in range(length))
    return password

@router.post("/")
async def create_trans(user_data: UserSchema):
    new_auth_user = None
    try:
        temp_password = generate_temp_password()
        
        new_auth_user = firebase_auth.create_user(
            email=user_data.email,
            password=temp_password,
        )
        uid = new_auth_user.uid

        firebase_auth.set_custom_user_claims(uid, {"rol": ["transportista"]})

        # Generar link de correo
        try:
            reset_link = firebase_auth.generate_password_reset_link(user_data.email)
        except Exception:
            reset_link = None
        
        # Guardar en Firestore usando el mismo UID
        user_dict = user_data.model_dump()
        # Asegurarse de que el rol sea correcto, aunque venga en el schema
        if "transportista" not in user_dict.get("rol", []):
             user_dict["rol"] = ["transportista"]
             
        doc_ref = db.collection("users").document(uid)
        doc_ref.set(user_dict)
        
        return {
            "message": "Transportista creado con éxito",
            "uid": uid,
            "temp_password": temp_password,
            "password_reset_link": reset_link
        }

    except firebase_auth.EmailAlreadyExistsError:
        raise HTTPException(status_code=400, detail="El email ya está registrado en el sistema")
    except Exception:
        if new_auth_user is not None:
            try:
                firebase_auth.delete_user(new_auth_user.uid)
            except Exception:
                pass
        raise HTTPException(status_code=500, detail="Error interno del servidor")

@router.put("/{uid}")
async def update_trans(uid: str, user_data: UserSchema):
    doc_ref = db.collection("users").document(uid)
    
    if not doc_ref.get().exists:
        raise HTTPException(status_code=404, detail="Transportista no encontrado")
        
    doc_ref.update(user_data.model_dump(exclude_unset=True))
    return {"message": "Transportista actualizado con éxito"}

@router.delete("/{uid}")
async def delete_trans(uid: str):
    try:
        doc_ref = db.collection("users").document(uid)

        doc = doc_ref.get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        doc_data = doc.to_dict() or {}
        rol = doc_data.get("rol", [])
        if isinstance(rol, str):
            rol = [rol]
        if "transportista" not in rol:
            raise HTTPException(status_code=400, detail="El usuario indicado no es transportista")

        # TODO: Cuando exista CRUD de tareas, bloquear borrado si existe
        # alguna tarea (carga o mantenimiento) con tareas.transportistaId == uid.

        vehiculo_id = doc_data.get("vehiculoId")
        if vehiculo_id is not None:
            # Se limpia la referencia local antes de la baja definitiva.
            doc_ref.update({"vehiculoId": None})

        # También se elimina la cuenta en Firebase Auth.
        try:
            firebase_auth.delete_user(uid)
        except firebase_auth.UserNotFoundError:
            pass

        doc_ref.delete()

        if vehiculo_id is not None:
            return {"message": "Transportista eliminado con éxito y vehículo liberado"}

        return {"message": "Transportista eliminado con éxito"}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")

