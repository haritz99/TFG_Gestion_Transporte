from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import Field

from .base import FirestoreSchema


class IncidenciaSchema(FirestoreSchema):
    descripcion: str = Field(..., min_length=1)
    fecha: datetime
    transportistaId: str = Field(..., min_length=1)
    tareaId: Optional[str] = None

