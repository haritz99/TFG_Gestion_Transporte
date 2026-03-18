from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import Field

from .base import FirestoreSchema


class CartaDePorteSchema(FirestoreSchema):
    cargaId: str = Field(..., min_length=1)
    encargadoId: Optional[str] = None
    transportistaId: str = Field(..., min_length=1)
    matVehi: str = Field(..., min_length=1)
    matRemol: str = Field(..., min_length=1)
    expedidor: str = Field(..., min_length=1)
    cargador: str = Field(..., min_length=1)
    destinatario: str = Field(..., min_length=1)
    mercancia: str = Field(..., min_length=1)
    cantidad: float = Field(..., gt=0)
    cargoRec: Optional[str] = None
    nombreRec: Optional[str] = None
    observaciones: Optional[str] = None
    fechaCarga: datetime
    fechaEntrega: Optional[datetime] = None

