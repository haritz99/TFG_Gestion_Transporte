from __future__ import annotations
from typing import Literal
from pydantic import BaseModel


class IncidenciaSchema(BaseModel):
    tipo: Literal["averia", "accidente", "retraso", "mercancia_danada", "otro"]
    descripcion: str
