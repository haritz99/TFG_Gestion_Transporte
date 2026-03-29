from __future__ import annotations

import re
from typing import Optional

from pydantic import Field, field_validator, model_validator

from .base import FirestoreSchema


class VehiculoSchema(FirestoreSchema):
    matricula: str = Field(..., min_length=3)
    marca: str = Field(..., min_length=1)
    modelo: str = Field(..., min_length=1)
    capacidad: float = Field(..., gt=0)
    largo: float = Field(..., gt=0)
    ancho: float = Field(..., gt=0)
    alto: float = Field(..., gt=0)
    disponible: bool
    interno: bool
    matriculaRemolque: Optional[str] = Field(default=None, min_length=3)
    companyId: str = None
    transportistaId: Optional[str] = None


    @field_validator('matricula')
    @classmethod
    def validate_matricula(cls, value: str):
        value = value.strip().upper()
        regex = r'^[0-9]{4}[A-Z]{3}$'
        if not re.match(regex, value):
            raise ValueError('La matrícula no cumple con el formato requerido')
        return value

    @field_validator('matriculaRemolque')
    @classmethod
    def validate_matricula_remolque(cls, value: Optional[str]):
        if value is None:
            return None
        value = value.strip().upper()
        regex = r'^[0-9]{4}[A-Z]{3}$'
        if not re.match(regex, value):
            raise ValueError('La matrícula de remolque no cumple con el formato requerido')
        return value

    @model_validator(mode='after')
    def check_disponibilidad(self) -> 'VehiculoSchema':
        """
        Un vehículo es disponible si y solo si transportistaId es None.
        """
        if self.transportistaId is not None:
            if self.disponible:
                raise ValueError('Un vehículo con transportista asignado no puede estar disponible')
        else:
            if not self.disponible:
                raise ValueError('Un vehículo sin transportista asignado debería estar disponible')

        if self.interno and not self.matriculaRemolque:
            raise ValueError('matriculaRemolque es obligatoria cuando interno es true')

        return self

