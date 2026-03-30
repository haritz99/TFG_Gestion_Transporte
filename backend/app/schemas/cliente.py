from typing import List, Optional
from pydantic import Field
from fastapi import HTTPException
from .base import FirestoreSchema

class ClienteSchema(FirestoreSchema):
    id: Optional[str] = None
    nombreComercial: str = Field(..., min_length=1)
    pedidos: List[str] = Field(default_factory=list)
    companyId: str = Field(..., min_length=1)

    @classmethod
    def from_firestore(cls, doc, company_id):
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Cliente no encontrado")
        data = doc.to_dict()
        data["id"] = doc.id
        if company_id != data.get("companyId"):
            raise HTTPException(status_code=403, detail="No autorizado para obtener este cliente")
        return cls(**data)