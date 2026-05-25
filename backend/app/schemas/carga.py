from __future__ import annotations

import datetime
import enum
from typing import Optional, TYPE_CHECKING
from fastapi import HTTPException
from pydantic import Field, model_validator

from .base import FirestoreSchema, BaseModel, DatetimeUTCMixin

if TYPE_CHECKING:
    from .pedido import PedidoSchema


class EstadoCarga(str, enum.Enum):
    PENDIENTE = 'pendiente'
    ASIGNADO = 'asignado'
    EN_TRANSITO = 'en_transito'
    ENTREGADO = 'entregado'
    CEDIDO = 'cedido'


class CargaBaseSchema(FirestoreSchema, DatetimeUTCMixin):
    origen: str = Field(..., min_length=1)
    destino: str = Field(..., min_length=1)
    mercancia: str = Field(..., min_length=1)
    numBultos: int = Field(..., gt=0)
    peso: float = Field(..., gt=0)
    precio: float = Field(..., gt=0)
    largo: Optional[float] = Field(default=None, gt=0)
    ancho: Optional[float] = Field(default=None, gt=0)
    alto: Optional[float] = Field(default=None, gt=0)


class CartaDePorteSnapshotSchema(BaseModel):
    # Datos del Cargador
    clienteNombre: str
    clienteNif: str
    clienteDireccion: str
    clienteTelefono: Optional[str] = None

    # Datos del Subcontratado (no siempre aplica)
    subcontratadoNombre: Optional[str] = None
    subcontratadoNif: Optional[str] = None
    subcontratadoDireccion: Optional[str] = None
    subcontratadoTelefono: Optional[str] = None
    subcontratadoNumAutorizacion: Optional[str] = None

    # Snapshot de marcas de tiempo
    congeladoAt: Optional[datetime.datetime] = None


class CargaSchema(CargaBaseSchema):
    id: Optional[str] = None
    estado: EstadoCarga = Field(default=EstadoCarga.PENDIENTE)
    fechaCarga: datetime.datetime = Field(...)
    fechaDescarga: datetime.datetime = Field(...)
    transportistaId: Optional[str] = None
    conductorNombre: Optional[str] = None # Desnormalizacion para prevenir n+1
    pedidoId: Optional[str] = None
    vehiculoId: Optional[str] = None
    companyId: Optional[str] = None
    clienteId: Optional[str] = None
    cartaPorteSnapshot: Optional[CartaDePorteSnapshotSchema] = None
    createdAt: Optional[datetime.datetime] = None
    updatedAt: Optional[datetime.datetime] = None

    def validar_contra_pedido(self, pedido: PedidoSchema):
        """
        Valida que la carga cumpla con las restricciones de su pedido padre.
        Se debe llamar a este método desde el servicio/router tras obtener el pedido de la base de datos y validarlo con Pydantic.
        """
        if self.fechaCarga < pedido.fechaCarga:
            raise ValueError(f"La fecha de carga ({self.fechaCarga}) no puede ser anterior a la del pedido ({pedido.fechaCarga}).")
        if self.fechaDescarga > pedido.fechaDescarga:
            raise ValueError(f"La fecha de descarga ({self.fechaDescarga}) no puede ser posterior a la del pedido ({pedido.fechaDescarga}).")

        if pedido.origenes and self.origen not in pedido.origenes:
            raise ValueError(f"El origen '{self.origen}' no existe en los orígenes válidos del pedido.")
        if pedido.destinos and self.destino not in pedido.destinos:
            raise ValueError(f"El destino '{self.destino}' no existe en los destinos válidos del pedido.")
    """
     @model_validator(mode='after')
    def validar_fechas(self) -> 'CargaSchema':
        if self.fechaDescarga <= self.fechaCarga:
            raise ValueError('La fecha de descarga debe ser posterior a la fecha de carga.')
        return self
    """


    @model_validator(mode='after')
    def validar_asignacion_estado(self) -> 'CargaSchema':
        if self.estado in (EstadoCarga.ASIGNADO, EstadoCarga.EN_TRANSITO, EstadoCarga.ENTREGADO):
            if not self.transportistaId and not self.vehiculoId:
                raise ValueError(f'Una carga en estado {self.estado.value} debe tener al menos un conductor o vehículo asignado.')
        return self

    @model_validator(mode='after')
    def validar_estado_pendiente(self) -> 'CargaSchema':
        if self.estado == EstadoCarga.PENDIENTE and (self.transportistaId and self.vehiculoId):
            raise ValueError('Una carga con conductor y vehículo ya asignado no puede seguir en estado pendiente.')
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


# Tipo de carga que estará prefijada
class TipoCargaSchema(CargaBaseSchema):
    id: Optional[str] = None
    nombre: str = Field(..., min_length=1)
    descripcion: Optional[str] = None
    pesoMax: float = Field(..., gt=0)
    companyId: str = Field(..., min_length=1)
    clienteId: str = Field(..., min_length=1) # Con qué cargador se prefija (no todos tienen las mismas)
    createdAt: Optional[datetime.datetime] = None
    updatedAt: Optional[datetime.datetime] = None

    @classmethod
    def from_firestore(cls, doc, company_id):
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Tipo de carga no encontrado")
        data = doc.to_dict()
        data["id"] = doc.id
        if company_id != data.get("companyId"):
            raise HTTPException(status_code=403, detail="No autorizado para usar este tipo de carga")
        return cls(**data)