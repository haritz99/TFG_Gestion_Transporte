from fastapi import APIRouter, Depends, HTTPException
from ..schemas.users import UserSchema
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db
from firebase_admin import auth as firebase_auth

router = APIRouter(prefix="/users", tags=["users"], dependencies=[Depends(get_current_encargado)])


@router.get("/trans")
async def get_all_trans():

    users_ref = db.collection("users")

    query = users_ref.where("rol", "array_contains", "transportista").stream()
    
    transportistas = []
    for doc in query:
        user_data = doc.to_dict()
        user_data["uid"] = doc.id
        transportistas.append(user_data)
        
    return transportistas


@router.get("/trans/{uid}")
async def get_trans(uid: str):
    doc_ref = db.collection("users").document(uid)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="Transportista no encontrado")
        
    user_data = doc.to_dict()
    user_data["uid"] = doc.id
    return user_data


@router.post("/trans")
async def create_trans(user_data: UserSchema):
    try:
        new_auth_user = firebase_auth.create_user(
            email=user_data.email,
            password="password_temporal_o_generada"     # falta logica de cambiar password
        )
        uid = new_auth_user.uid

        doc_ref = db.collection("users").document(uid)
        doc_ref.set(user_data.model_dump())
        return {"message": "Transportista creado con éxito", "id": doc_ref.id}

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/trans/{uid}")
async def update_trans(uid: str, user_data: UserSchema):
    doc_ref = db.collection("users").document(uid)
    
    if not doc_ref.get().exists:
        raise HTTPException(status_code=404, detail="Transportista no encontrado")
        
    doc_ref.update(user_data.model_dump(exclude_unset=True))
    return {"message": "Transportista actualizado con éxito"}

@router.delete("/trans/{uid}")
async def delete_trans(uid: str):

    doc_ref = db.collection("users").document(uid)
    doc_ref.delete()
    return {"message": "Transportista eliminado con éxito"}
