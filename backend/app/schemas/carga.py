from __future__ import annotations

import datetime
import enum
import math
import re
from typing import Optional, TYPE_CHECKING
from fastapi import HTTPException
from pydantic import Field, field_validator, model_validator

from .base import FirestoreSchema, BaseModel, to_utc
from .direccion import UbicacionSchema
from .vehiculos import VehiculoSchema

if TYPE_CHECKING:
    from .pedido import PedidoSchema, CreatePedidoSchema

_NOMBRE_APELLIDOS_REGEX = re.compile(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)+$")
_MATRICULA_REGEX = re.compile(r"^\d{4}[BCDFGHJKLMNPRSTVWXYZ]{3}$")


class EstadoCarga(str, enum.Enum):
    PENDIENTE = 'pendiente'
    PLANIFICADO = 'planificado' # en calendario pero sin asignar aun
    ASIGNADO = 'asignado'
    EN_TRANSITO = 'en_transito'
    ENTREGADO = 'entregado'
    CEDIDO = 'cedido'

class TipoCarga(str, enum.Enum):
    BULTOS = 'bultos'
    GRANEL = 'granel'
    LIQUIDO = 'liquido'

class CartaDePorteSnapshotSchema(BaseModel):
    # Datos del Cargador
    clienteNombre: str
    clienteNif: str
    clienteDireccion: str
    clienteTelefono: Optional[str] = None

    # Datos del cliente (como llamo cliente al cargador, este se llama destinatario)
    destinatarioNombre: Optional[str] = None
    destinatarioNif: Optional[str] = None
    destinatarioDireccion: Optional[str] = None

    # Datos del Subcontratado (no siempre aplica)
    subcontratadoNombre: Optional[str] = None
    subcontratadoNif: Optional[str] = None
    subcontratadoDireccion: Optional[str] = None
    subcontratadoTelefono: Optional[str] = None
    subcontratadoNumAutorizacion: Optional[str] = None

    subVehiculoMatricula: Optional[str] = None
    subRemolqueMatricula: Optional[str] = None

    precioNeto: Optional[float] = None # lo que cobra el subcontratado (despues de la comision)
    # Snapshot de marcas de tiempo
    congeladoAt: Optional[datetime.datetime] = None

class CargaBaseSchema(FirestoreSchema):
    tipoCarga: TipoCarga = TipoCarga.BULTOS
    origen: UbicacionSchema
    destino: UbicacionSchema
    mercancia: str = Field(..., min_length=1)
    tipoEmbalaje: Optional[str] = None
    numBultos: Optional[int] = Field(default=None, gt=0)
    peso: Optional[float] = Field(default=None, gt=0)
    precio: float = Field(..., gt=0)
    apilable: bool = False
    volumen: Optional[float] = Field(default=None, gt=0)
    longitudLineal: Optional[float] = Field(default=None, gt=0)
    largo: Optional[float] = Field(default=None, gt=0)
    ancho: Optional[float] = Field(default=None, gt=0)
    alto: Optional[float] = Field(default=None, gt=0)

    @model_validator(mode='after')
    def calcular_volumen_y_longitud_lineal(self) -> 'CargaBaseSchema':
        if (self.tipoCarga == TipoCarga.BULTOS
            and self.numBultos and self.largo and self.ancho and self.alto):
            self.volumen = math.ceil(self.largo * self.ancho * self.alto * self.numBultos)

        # Longitud lineal: metros de suelo ocupados
        if self.numBultos and self.largo and self.ancho:
            unidades_suelo = (self.numBultos / 2) if self.apilable else self.numBultos
            self.longitudLineal = round((self.largo * self.ancho / 2.4) * unidades_suelo, 2)

        return self

class CargaSchema(CargaBaseSchema):
    id: Optional[str] = None
    estado: EstadoCarga = Field(default=EstadoCarga.PENDIENTE)
    fechaCarga: datetime.datetime = Field(...)
    fechaDescarga: datetime.datetime = Field(...)
    bufferHours: Optional[int] = None
    transportistaId: Optional[str] = None
    conductorNombre: Optional[str] = None # Desnormalizacion para prevenir n+1
    pedidoId: Optional[str] = None
    vehiculoId: Optional[str] = None
    comisionCesion: Optional[float] = Field(default=None, ge=0, le=100)
    companyId: Optional[str] = None
    clienteId: Optional[str] = None
    subcontratadoId: Optional[str] = None
    cartaPorteSnapshot: Optional[CartaDePorteSnapshotSchema] = None
    carta_porte_url: Optional[str] = None
    createdAt: Optional[datetime.datetime] = None
    updatedAt: Optional[datetime.datetime] = None

    def validar_contra_pedido(self, pedido: PedidoSchema | CreatePedidoSchema):
        """
        Valida que la carga cumpla con las restricciones de su pedido padre.
        Se debe llamar a este método desde el servicio/router tras obtener el pedido de la base de datos y validarlo con Pydantic.
        """
        fecha_carga_self = to_utc(self.fechaCarga)
        fecha_carga_pedido = to_utc(pedido.fechaCarga)
        if fecha_carga_self < fecha_carga_pedido:
            raise ValueError(f"La fecha de carga ({self.fechaCarga}) no puede ser anterior a la del pedido ({pedido.fechaCarga}).")

    def validar_contra_vehiculo(self, vehiculo: VehiculoSchema):
        if self.peso is not None and self.peso > vehiculo.capacidad:
            raise ValueError(
                f"El peso de la carga ({self.peso} kg) excede la capacidad del vehículo {vehiculo.matricula} ({vehiculo.capacidad} kg)."
            )
        if self.longitudLineal is not None and self.longitudLineal > vehiculo.largo:
            raise ValueError(
                f"La longitud lineal de la carga ({self.longitudLineal} m) excede la longitud del vehículo {vehiculo.matricula} ({vehiculo.largo} m)."
            )

    
    @model_validator(mode='after')
    def validar_fechas(self) -> 'CargaSchema':
        self.fechaCarga = to_utc(self.fechaCarga)
        self.fechaDescarga = to_utc(self.fechaDescarga)
        if self.fechaDescarga <= self.fechaCarga:
            raise ValueError('La fecha de descarga debe ser posterior a la fecha de carga.')
        return self
    
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
    pesoMax: Optional[float] = Field(default=None, gt=0)
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

class CargaUpdateSubSchema(BaseModel):
    estado: EstadoCarga | None = None
    conductorNombre: str | None = Field(default=None)
    subVehiculoMatricula: str | None = Field(default=None)
    subRemolqueMatricula: str | None = Field(default=None)

    @field_validator("conductorNombre")
    @classmethod
    def validar_nombre_apellidos(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalizado = " ".join(value.strip().split())
        if not _NOMBRE_APELLIDOS_REGEX.fullmatch(normalizado):
            raise ValueError("El nombre del conductor debe incluir nombre y apellidos válidos")
        return normalizado

    @field_validator("subVehiculoMatricula", "subRemolqueMatricula")
    @classmethod
    def validar_matricula_es(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalizado = value.strip().upper().replace("-", "").replace(" ", "")
        if not _MATRICULA_REGEX.fullmatch(normalizado):
            raise ValueError("La matrícula debe tener formato correcto")
        return normalizado
