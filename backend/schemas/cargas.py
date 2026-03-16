from __future__ import annotations

from typing import Optional

from pydantic import Field

from .base import FirestoreSchema


class CargaSchema(FirestoreSchema):
    peso: float = Field(..., gt=0)
    largo: float = Field(..., gt=0)
    ancho: float = Field(..., gt=0)
    alto: float = Field(..., gt=0)
    tareaId: Optional[str] = None
    rutaId: Optional[str] = None

