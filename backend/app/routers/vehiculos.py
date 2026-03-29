from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from ..schemas import VehiculoSchema
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db


router = APIRouter(prefix="/vehi", tags=["vehiculos"], dependencies=[Depends(get_current_encargado)])


class VehiculoAssignSchema(BaseModel):
    matr: str = Field(..., min_length=3)
    uid: str = Field(..., min_length=1)

@router.get("/")
async def get_all_vehiculos(current_user: dict[str, Any] = Depends(get_current_encargado)):
    try:
        company_id = current_user["companyId"]
        vehiculos_ref = db.collection("vehiculos")
        query = vehiculos_ref.where("companyId", "==", company_id).stream()
        vehiculos = []
        for doc in query:
            vehiculos.append(doc.to_dict())
        return vehiculos
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")

@router.get("/{matr}")
async def get_vehiculo(matr: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    try:
        company_id = current_user["companyId"]
        doc_ref = db.collection("vehiculos").document(matr.upper())
        doc = doc_ref.get()

        if not doc.exists:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        vehiculo_data = doc.to_dict() or {}
        if vehiculo_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        return vehiculo_data
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.post("/")
async def create_vehiculo(
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
):
    try:
        company_id = current_user["companyId"]
        new_vehiculo = vehiculo_data.model_dump()
        new_vehiculo["companyId"] = company_id

        doc_ref = db.collection("vehiculos").document(vehiculo_data.matricula)
        if doc_ref.get().exists:
            raise HTTPException(status_code=409, detail="Ya existe un vehículo con esa matrícula")

        doc_ref.set(new_vehiculo)
        return {"message": "Vehículo creado con éxito"}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.put("/{matr}")
async def update_vehiculo(
    matr: str,
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
):
    try:
        company_id = current_user["companyId"]
        doc_ref = db.collection("vehiculos").document(matr.upper())
        doc = doc_ref.get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        doc_data = doc.to_dict() or {}
        if doc_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        update_data = vehiculo_data.model_dump(exclude_unset=True)
        update_data["companyId"] = company_id   # Para prevenir que alguien pueda cambiar el companyId

        doc_ref.update(update_data)
        return {"message": "Vehículo actualizado con éxito"}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.delete("/{matr}")
async def delete_vehiculo(matr: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    try:
        company_id = current_user["companyId"]
        doc_ref = db.collection("vehiculos").document(matr.upper())
        doc = doc_ref.get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        doc_data = doc.to_dict() or {}
        if doc_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        doc_ref.delete()
        return {"message": "Vehículo eliminado con éxito"}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.patch("/assign")
async def asignar_vehiculo_a_transportista(
    data: VehiculoAssignSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
):
    try:
        company_id = current_user["companyId"]

        vehiculo_ref = db.collection("vehiculos").document(data.matr.upper())
        vehiculo_doc = vehiculo_ref.get()
        if not vehiculo_doc.exists:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        vehiculo_data = vehiculo_doc.to_dict() or {}
        if vehiculo_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Vehículo no encontrado")

        transportista_ref = db.collection("users").document(data.uid)
        transportista_doc = transportista_ref.get()
        if not transportista_doc.exists:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        batch = db.batch()

        batch.update(vehiculo_ref, {"transportistaId": data.uid})
        batch.update(transportista_ref, {"vehiculoId": data.matr.upper()})

        # Se ejecutan ambas a la vez para evitar inconsistencias
        batch.commit()

        return {"message": "Vehículo asignado con éxito"}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")




