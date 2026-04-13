from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from ..schemas import VehiculoSchema
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db


router = APIRouter(prefix="/vehi", tags=["vehiculos"], dependencies=[Depends(get_current_encargado)])


class VehiculoAssignSchema(BaseModel):
    matr: str = Field(..., min_length=3)
    uid: str = Field(..., min_length=1)


def _build_transportista_name(user_data: dict[str, Any]) -> str:
    nombre = user_data.get("nombre") or ""
    apellido = user_data.get("apellido") or ""
    full_name = nombre.strip() + " " + apellido.strip()
    return full_name

@router.get("/", response_model=list[VehiculoSchema])
async def get_all_vehiculos(current_user: dict[str, Any] = Depends(get_current_encargado)) -> list[VehiculoSchema]:
    try:
        company_id = current_user["companyId"]
        vehiculos_ref = db.collection("vehiculos")
        query = vehiculos_ref.where("companyId", "==", company_id).stream()
        vehiculos = []
        for doc in query:
            vehiculo = VehiculoSchema.from_firestore(doc, company_id)
            vehiculos.append(vehiculo)
        return vehiculos
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.get("/{matr}", response_model=VehiculoSchema)
async def get_vehiculo(
    matr: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
) -> VehiculoSchema:
    try:
        company_id = current_user["companyId"]
        doc_ref = db.collection("vehiculos").document(matr.upper())
        doc = doc_ref.get()

        vehiculo = VehiculoSchema.from_firestore(doc, company_id)
        return vehiculo
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=VehiculoSchema)
async def create_vehiculo(
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
) -> VehiculoSchema:
    try:
        company_id = current_user["companyId"]
        vehiculo_data.companyId = company_id

        doc_ref = db.collection("vehiculos").document(vehiculo_data.matricula)
        if doc_ref.get().exists:
            raise HTTPException(status_code=409, detail="Ya existe un vehículo con esa matrícula")

        batch = db.batch()
        batch.set(doc_ref, vehiculo_data.model_dump())

        # Si hay transportista se actualiza el vehiculoId del transportista
        if vehiculo_data.transportistaId:
            transportista_ref = db.collection("users").document(vehiculo_data.transportistaId)
            batch.update(transportista_ref, {"vehiculoId": vehiculo_data.matricula})

        batch.commit()

        return vehiculo_data
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.put("/{matr}", response_model=VehiculoSchema)
async def update_vehiculo(
    matr: str,
    vehiculo_data: VehiculoSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
) -> VehiculoSchema:
    try:
        company_id = current_user["companyId"]
        doc_ref = db.collection("vehiculos").document(matr.upper())
        doc = doc_ref.get()
        vehiculo_antiguo = VehiculoSchema.from_firestore(doc, company_id)

        vehiculo_data.companyId = company_id  # Se sobreescribe con el valor del token

        batch = db.batch()
        batch.update(doc_ref, vehiculo_data.model_dump())

        transportista_viejo_id = vehiculo_antiguo.transportistaId
        transportista_nuevo_id = vehiculo_data.transportistaId

        # Aqui se asigna o se desasigna el vehiculo al transportista
        if transportista_viejo_id != transportista_nuevo_id:
            if transportista_viejo_id:
                viejo_ref = db.collection("users").document(transportista_viejo_id)
                batch.update(viejo_ref, {"vehiculoId": None})

            if transportista_nuevo_id:
                nuevo_ref = db.collection("users").document(transportista_nuevo_id)
                batch.update(nuevo_ref, {"vehiculoId": vehiculo_data.matricula})

        batch.commit()
        return vehiculo_data
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.delete("/{matr}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vehiculo(matr: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    try:
        company_id = current_user["companyId"]
        doc_ref = db.collection("vehiculos").document(matr.upper())
        doc = doc_ref.get()
        vehiculo = VehiculoSchema.from_firestore(doc, company_id)
        
        batch = db.batch()
        batch.delete(doc_ref)
        
        if vehiculo.transportistaId:
            transportista_ref = db.collection("users").document(vehiculo.transportistaId)
            batch.update(transportista_ref, {"vehiculoId": None})
            
        batch.commit()
        return None
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")


@router.patch("/assign", response_model=VehiculoSchema)
async def asignar_vehiculo_a_transportista(
    data: VehiculoAssignSchema,
    current_user: dict[str, Any] = Depends(get_current_encargado),
) -> VehiculoSchema:
    try:
        company_id = current_user["companyId"]

        vehiculo_ref = db.collection("vehiculos").document(data.matr.upper())
        vehiculo_doc = vehiculo_ref.get()
        vehiculo = VehiculoSchema.from_firestore(vehiculo_doc, company_id)

        transportista_ref = db.collection("users").document(data.uid)
        transportista_doc = transportista_ref.get()
        if not transportista_doc.exists:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        transportista_data = transportista_doc.to_dict() or {}
        transportista_nombre = _build_transportista_name(transportista_data)

        batch = db.batch()

        batch.update(
            vehiculo_ref,
            {
                "transportistaId": data.uid,
                "transportistaNombre": transportista_nombre,
                "estado": "asignado",
            },
        )
        batch.update(transportista_ref, {"vehiculoId": data.matr.upper()})

        batch.commit()

        return VehiculoSchema(
            **vehiculo.model_dump(),
            transportistaId=data.uid,
            transportistaNombre=transportista_nombre,
            estado="asignado",
        )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Error interno del servidor")
