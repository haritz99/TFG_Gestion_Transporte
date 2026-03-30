from typing import List
from pydantic import Field

from .base import FirestoreSchema

class ClienteSchema(FirestoreSchema):
    nombreComercial: str = Field(..., min_length=1)
    pedidos: List[str] = Field(default_factory=list)
    companyId: str = Field(..., min_length=1)
