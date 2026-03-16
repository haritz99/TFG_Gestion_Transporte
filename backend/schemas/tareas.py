from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import Field

from .base import FirestoreSchema


class TareaSchema(FirestoreSchema):
    encargadoId: Optional[str] = None
    transportistaId: Optional[str] = None
    fechaIni: datetime
    fechaFin: Optional[datetime] = None

