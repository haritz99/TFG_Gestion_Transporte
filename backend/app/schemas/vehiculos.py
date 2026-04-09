from __future__ import annotations

import re
from typing import Literal, Optional

from fastapi import HTTPException
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
    estado: Literal['asignado', 'disponible', 'mantenimiento']
    interno: bool  # subcontratado
    matriculaRemolque: Optional[str] = Field(default=None, min_length=3)
    companyId: Optional[str] = Field(default=None, min_length=1)
    transportistaId: Optional[str] = None
    transportistaNombre: Optional[str] = None


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
    def check_estado(self) -> 'VehiculoSchema':
        if self.estado == 'asignado':
            if self.transportistaId is None:
                raise ValueError('Un vehículo asignado debe tener transportistaId')
            if not self.transportistaNombre:
                raise ValueError('Un vehículo asignado debe tener transportistaNombre')
        else:
            if self.transportistaId or self.transportistaNombre:
                raise ValueError('Un vehículo disponible o en mantenimiento no puede tener transportista asignado')

        if self.interno and not self.matriculaRemolque:
            raise ValueError('matriculaRemolque es obligatoria cuando interno es true')

        return self

    @classmethod
    def from_firestore(cls, doc, company_id: str):
        if not doc.exists:
            raise HTTPException(status_code=404, detail='Vehículo no encontrado')

        data = doc.to_dict() or {}
        if company_id != data.get('companyId'):
            raise HTTPException(status_code=403, detail='No autorizado para usar este vehículo')

        return cls(**data)

