from typing import List
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
    descripcion: str = Field(..., min_length=1)
    fechaCarga: datetime.datetime = Field(...)  # Fecha de carga
    fechaDescarga: datetime.datetime = Field(...) # Fecha de descarga maxima
    origenes: List[str] = Field(..., min_length=1)  # Lista de origenes
    destinos: List[str] = Field(..., min_length=1)  # Lista de destinos
    estado: EstadoPedido = Field(default=EstadoPedido.PLANIFICADO)
    clienteId: str = Field(..., min_length=1) 
    companyId: str = Field(..., min_length=1)

    @model_validator(mode='after')
    def validar_fechas_pedido(self) -> 'PedidoSchema':
        if self.fechaDescarga <= self.fechaCarga:
            raise ValueError('La fecha límite de descarga del pedido debe ser posterior a la fecha de carga.')
        return self
