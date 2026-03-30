from __future__ import annotations

import datetime
import enum
from typing import Optional, TYPE_CHECKING
from fastapi import HTTPException
from pydantic import Field, model_validator

from .base import FirestoreSchema

if TYPE_CHECKING:
    from .pedido import PedidoSchema


class EstadoCarga(str, enum.Enum):
    PENDIENTE = 'pendiente'
    ASIGNADO = 'asignado'
    EN_TRANSITO = 'en_transito'
    ENTREGADO = 'entregado'


class CargaSchema(FirestoreSchema):
    id: Optional[str] = None
    origen: str = Field(..., min_length=1)
    destino: str = Field(..., min_length=1)
    mercancia: str = Field(..., min_length=1)   #tipo de mercancia
    numBultos: int = Field(..., gt=0)
    peso: Optional[float] = Field(..., gt=0)
    largo: Optional[float] = Field(..., gt=0)
    ancho: Optional[float] = Field(..., gt=0)
    alto: Optional[float] = Field(..., gt=0)
    estado: EstadoCarga = Field(default=EstadoCarga.PENDIENTE)
    fechaCarga: datetime.datetime = Field(...)
    fechaDescarga: datetime.datetime = Field(...)
    transportistaId: Optional[str] = None
    pedidoId: Optional[str] = None
    vehiculoId: Optional[str] = None
    rutaId: Optional[str] = None
    companyId: str = Field(..., min_length=1)
    clienteId: Optional[str] = None

    def validar_contra_pedido(self, pedido: 'PedidoSchema'):
        """
        Valida que la carga cumpla con las restricciones de su pedido padre.
        Se debe llamar a este método desde el servicio/router tras obtener el pedido de la base de datos y validarlo con Pydantic.
        """
        # Validar fechas
        if self.fechaCarga < pedido.fechaCarga:
            raise ValueError(f"La fecha de carga ({self.fechaCarga}) no puede ser anterior a la del pedido ({pedido.fechaCarga}).")
        if self.fechaDescarga > pedido.fechaDescarga:
            raise ValueError(f"La fecha de descarga ({self.fechaDescarga}) no puede ser posterior a la del pedido ({pedido.fechaDescarga}).")

        # Validar orígenes y destinos
        if self.origen not in pedido.origenes:
            raise ValueError(f"El origen '{self.origen}' no existe en los orígenes válidos del pedido.")
        if self.destino not in pedido.destinos:
            raise ValueError(f"El destino '{self.destino}' no existe en los destinos válidos del pedido.")

    @model_validator(mode='after')
    def validar_fechas(self) -> 'CargaSchema':
        if self.fechaDescarga <= self.fechaCarga:
            raise ValueError('La fecha de descarga debe ser posterior a la fecha de carga.')
        return self

    @model_validator(mode='after')
    def validar_asignacion_estado(self) -> 'CargaSchema':
        if self.estado in (EstadoCarga.ASIGNADO, EstadoCarga.EN_TRANSITO, EstadoCarga.ENTREGADO):
            if not self.transportistaId and not self.vehiculoId:
                raise ValueError(f'Una carga en estado {self.estado.value} debe tener al menos un transportista o vehículo asignado.')
        return self

    @model_validator(mode='after')
    def validar_estado_pendiente(self) -> 'CargaSchema':
        if self.estado == EstadoCarga.PENDIENTE and (self.transportistaId or self.vehiculoId):
            raise ValueError('Una carga con transportista o vehículo ya asignado no puede seguir en estado pendiente.')
        return self

    @classmethod
    def from_firestore(cls, doc, company_id):
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")
        data = doc.to_dict()
        data["id"] = doc.id
        if company_id != data.get("companyId"):
            raise HTTPException(status_code=403, detail="No autorizado para usar esta carga")
        return cls(**data)
