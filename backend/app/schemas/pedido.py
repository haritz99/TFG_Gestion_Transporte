from typing import List, Optional
from fastapi import HTTPException
import datetime

from pydantic import Field, model_validator

from .base import FirestoreSchema
import enum

class EstadoPedido(str, enum.Enum):
    PLANIFICADO = 'planificado'
    EN_PROGRESO = 'en_progreso'
    COMPLETADO = 'completado'
    CANCELADO = 'cancelado'

class PedidoSchema(FirestoreSchema):
    id: Optional[str] = None
    descripcion: str = Field(..., min_length=1)
    fechaCarga: datetime.datetime = Field(...)  # Fecha de carga
    fechaDescarga: datetime.datetime = Field(...) # Fecha de descarga maxima
    origenes: List[str] = Field(..., min_length=1)  # Lista de origenes
    destinos: List[str] = Field(..., min_length=1)  # Lista de destinos
    estado: EstadoPedido = Field(default=EstadoPedido.PLANIFICADO)
    clienteId: str = Field(..., min_length=1) 
    companyId: Optional[str] = Field(default=None, min_length=1)

    @model_validator(mode='after')
    def validar_fechas_pedido(self) -> 'PedidoSchema':
        if self.fechaDescarga <= self.fechaCarga:
            raise ValueError('La fecha límite de descarga del pedido debe ser posterior a la fecha de carga.')
        return self

    @classmethod
    def from_firestore(cls, doc, company_id):
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Pedido no encontrado")
        data = doc.to_dict()
        data["id"] = doc.id
        if company_id != data.get("companyId"):
            raise HTTPException(status_code=403, detail="No autorizado para usar este pedido")
        return cls(**data)
