from typing import Any

from fastapi import  HTTPException
from datetime import datetime, timezone

from app.schemas import IncidenciaSchema
from ..firebase_config import db

class IncidenciaService:

    def __init__(self):
        self._db = db

    def create_incidencia(self, carga_id: str, data: IncidenciaSchema, current_user: dict[str, Any]) -> dict[str, str]:
        doc = data.model_dump()
        doc["cargaId"] = carga_id
        doc["conductorId"] = current_user["uid"]
        doc["companyId"] = current_user["companyId"]
        doc["resuelta"] = False
        doc["createdAt"] = datetime.now(timezone.utc)

        self._db.collection("incidencias").add(doc)
        return {"message": "Incidencia creada correctamente"}

    def resolver_incidencia(self, incidencia_id: str) -> dict[str, str]:
        ref = self._db.collection("incidencias").document(incidencia_id)
        doc = ref.get()

        if not doc.exists:
            raise HTTPException(status_code=404, detail="Incidencia no encontrada")

        ref.update({"resuelta": True})
        return {"message": "Incidencia resuelta"}