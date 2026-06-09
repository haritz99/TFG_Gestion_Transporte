from __future__ import annotations

import re
from typing import Optional

from fastapi import HTTPException
from pydantic import Field, field_validator

from .base import FirestoreSchema


class VehiculoSchema(FirestoreSchema):
    matricula: str = Field(..., min_length=3)
    marca: str = Field(..., min_length=1)
    modelo: str = Field(..., min_length=1)
    capacidad: float = Field(..., gt=0)
    largo: float = Field(..., gt=0)
    ancho: float = Field(..., gt=0)
    alto: float = Field(..., gt=0)
    matriculaRemolque: Optional[str] = Field(default=None, min_length=3)
    companyId: Optional[str] = Field(default=None, min_length=1)

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

    @classmethod
    def from_firestore(cls, doc, company_id: str):
        if not doc.exists:
            raise HTTPException(status_code=404, detail='Vehículo no encontrado')
        data = doc.to_dict() or {}
        data['matricula'] = doc.id
        if company_id != data.get('companyId'):
            raise HTTPException(status_code=403, detail='No autorizado para usar este vehículo')
        return cls(**data)

class VehiculoPaginatedSchema(FirestoreSchema):
    items: list[VehiculoSchema]
    last_doc_id: Optional[str] = None
    has_more: bool

class VehiculoAssignSchema(FirestoreSchema):
    matricula: str = Field(..., min_length=3)
    uid: str = Field(..., min_length=1)
