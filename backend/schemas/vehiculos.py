from __future__ import annotations

from typing import Optional

from pydantic import Field

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
    transportistaId: Optional[str] = None

