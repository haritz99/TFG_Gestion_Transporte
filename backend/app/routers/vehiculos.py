from fastapi import APIRouter, Depends, HTTPException

from ..schemas import VehiculoSchema
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db


router = APIRouter(prefix="/vehi", tags=["vehiculos"], dependencies=[Depends(get_current_encargado)])

@router.get("/")
async def get_all_vehiculos():
    try:
        vehiculos_ref = db.collection("vehiculos")
        query = vehiculos_ref.stream()
        vehiculos = []
        for doc in query:
            vehiculos.append(doc.to_dict())
        return vehiculos
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno del servidor")

@router.get("/{matr}")
async def get_vehiculo(matr: str):
    try:
        doc_ref = db.collection("vehiculo").document(matr)
        doc = doc_ref.get()

        if not doc.exists:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        vehiculo_data = doc.to_dict()
        return vehiculo_data
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.post("/")
async def create_vehiculo(vehiculo_data: VehiculoSchema):
    try:
        new_vehiculo = vehiculo_data.model_dump()
        doc_ref = db.collection("vehiculo").document
        doc_ref.set(new_vehiculo)
        return {"message": "Vehículo creado con éxito"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.put("/{matr}")
async def update_vehiculo(matr: str, vehiculo_data: VehiculoSchema):
    try:
        doc_ref = db.collection("vehiculo").document(matr)
        if not doc_ref.get().exists:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        doc_ref.update(vehiculo_data.model_dump(exclude_unset=True))
        return {"message": "Vehículo actualizado con éxito"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.delete("/{matr}")
async def delete_vehiculo(matr: str):
    try:
        doc_ref = db.collection("vehiculo").document(matr)
        doc_ref.delete()
        return {"message": "Vehículo eliminado con éxito"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.patch("/assign")
async def asignar_vehiculo_a_transportista(data):
    try:
        vehiculo_ref = db.collection("vehiculo").document(data.matr)
        vehiculo_doc = vehiculo_ref.get()
        if not vehiculo_doc.exists:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        transportista_ref = db.collection("users").document(data.uid)
        transportista_doc = transportista_ref.get()
        if not transportista_doc.exists:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        batch = db.batch()

        batch.update(vehiculo_ref, {"transportistaId": data.uid})
        batch.update(transportista_ref, {"vehiculoId": data.matr})

        # Se ejecutan ambas a la vez para evitar inconsistencias
        batch.commit()

        return {"message": "Vehículo asignado con éxito"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error interno del servidor")




