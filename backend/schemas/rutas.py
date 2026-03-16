from __future__ import annotations

from typing import Optional

from pydantic import Field

from .base import FirestoreSchema


class RutaSchema(FirestoreSchema):
    origen: str = Field(..., min_length=1)
    destino: str = Field(..., min_length=1)
    cargaId: Optional[str] = None

