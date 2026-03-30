from __future__ import annotations

import datetime
from typing import Any, Optional, List, Dict

from fastapi import APIRouter, Depends, Query, HTTPException, status
from pydantic import BaseModel, Field

from ..dependencies.auth import get_current_encargado
from ..dependencies.pedido_valido import get_pedido_from_carga
from ..firebase_config import db
from ..schemas.carga import CargaSchema, EstadoCarga
from ..schemas.pedido import PedidoSchema
from ..services.cargas_service import fetch_cargas

class CargaAssignSchema(BaseModel):
    transportistaId: str = Field(..., min_length=1)
    cargaId: str = Field(..., min_length=1)


router = APIRouter(prefix="/cargas", tags=["cargas"])

@router.get("/", response_model=list[CargaSchema])
def get_cargas(
    cliente_id: Optional[str] = Query(None, description="Filtrar por ID de cliente"),
    pedido_id: Optional[str] = Query(None, description="Filtrar por ID de pedido"),
    transportista_id: Optional[str] = Query(None, description="Filtrar por ID de transportista"),
    estado: Optional[EstadoCarga] = Query(None, description="Filtrar por estado"),
    fecha_inicio: Optional[datetime.date] = Query(None, description="Fecha inicio de carga (YYYY-MM-DD)"),
    fecha_fin: Optional[datetime.date] = Query(None, description="Fecha límite de carga (YYYY-MM-DD)"),
    current_user: dict[str, Any] = Depends(get_current_encargado)
):
    return fetch_cargas(
        company_id=current_user.get("companyId"),
        cliente_id=cliente_id,
        pedido_id=pedido_id,
        transportista_id=transportista_id,
        estado=estado,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin
    )

@router.get("/{carga_id}", response_model=CargaSchema)
def get_carga_by_id(carga_id: str,
                    current_user: dict[str, Any] = Depends(get_current_encargado)) -> CargaSchema:

    carga_ref = db.collection("cargas").document(carga_id)
    carga_doc = carga_ref.get()

    if not carga_doc.exists:
        raise HTTPException(status_code=404, detail="Carga no encontrada")

    return CargaSchema.from_firestore(carga_doc, current_user.get("companyId"))


@router.post("/", status_code=status.HTTP_201_CREATED)
def create_carga(carga: CargaSchema,
                 pedido_schema: PedidoSchema = Depends(get_pedido_from_carga),
                 current_user: dict[str, Any] = Depends(get_current_encargado)):

    carga.companyId = current_user.get("companyId")

    try:
        carga.validar_contra_pedido(pedido_schema)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
        
    # 4. Inyectar clienteId denormalizado para favorecer el filtrado a futuro
    carga.clienteId = pedido_schema.clienteId

    doc_ref = db.collection("cargas").document()
    carga.id = doc_ref.id
    nuevo_carga_dict = carga.model_dump()
    doc_ref.set(nuevo_carga_dict)

    return carga


@router.post("/assign", response_model=CargaSchema)
def assign_carga_transportista(
    data: CargaAssignSchema, 
    current_user: dict[str, Any] = Depends(get_current_encargado)
):
    company_id = current_user.get("companyId")
    carga_ref = db.collection("cargas").document(data.cargaId)
    carga_doc = carga_ref.get()

    if not carga_doc.exists:
        raise HTTPException(status_code=404, detail="Carga no encontrada")

    carga = CargaSchema.from_firestore(carga_doc, company_id)

    # Validar que el transportista existe
    trans_doc = db.collection("users").document(data.transportistaId).get()
    if not trans_doc.exists or trans_doc.to_dict().get("companyId") != company_id:
        raise HTTPException(status_code=404, detail="Transportista no encontrado")

    carga.transportistaId = data.transportistaId
    
    update_data = {"transportistaId": data.transportistaId}
    
    # Si estaba pendiente, lo pasamos a asignado automáticamente
    if carga.estado == EstadoCarga.PENDIENTE:
        carga.estado = EstadoCarga.ASIGNADO
        update_data["estado"] = EstadoCarga.ASIGNADO.value
        
    carga_ref.update(update_data)

    return carga


@router.put("/{carga_id}", response_model=CargaSchema)
def update_carga(carga_id: str, 
                 carga: CargaSchema, 
                 pedido_schema: PedidoSchema = Depends(get_pedido_from_carga),
                 current_user: dict[str, Any] = Depends(get_current_encargado)):
    
    company_id = current_user.get("companyId")
    carga_ref = db.collection("cargas").document(carga_id)
    carga_doc = carga_ref.get()

    if not carga_doc.exists:
        raise HTTPException(status_code=404, detail="Carga no encontrada")

    carga_data = carga_doc.to_dict()
    if carga_data.get("companyId") != company_id:
        raise HTTPException(status_code=403, detail="No autorizado para modificar esta carga")

    carga.companyId = company_id    # Se sobreescribe con el valor del token (mas seguridad)
    carga.id = carga_id             
        
    try:
        carga.validar_contra_pedido(pedido_schema)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    carga.clienteId = pedido_schema.clienteId
    update_data = carga.model_dump(exclude={'id'})
    
    carga_ref.update(update_data)

    return carga


@router.delete("/{carga_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_carga(carga_id: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    company_id = current_user.get("companyId")
    carga_ref = db.collection("cargas").document(carga_id)
    carga_doc = carga_ref.get()

    if not carga_doc.exists:
        raise HTTPException(status_code=404, detail="Carga no encontrada")

    carga_data = carga_doc.to_dict()
    if carga_data.get("companyId") != company_id:
        raise HTTPException(status_code=403, detail="No autorizado para eliminar esta carga")

    estado_actual = carga_data.get("estado")

    if estado_actual in [EstadoCarga.EN_TRANSITO.value, EstadoCarga.ENTREGADO.value]:
        raise HTTPException(
            status_code=400, 
            detail=f"No se puede eliminar una carga en estado {estado_actual}."
        )

    carga_ref.delete()
    return None
