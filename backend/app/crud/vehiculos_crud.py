from typing import Any

from app.firebase_config import get_db
from app.interfaces.i_repository import IRepository
from app.schemas.vehiculos import VehiculoSchema


class VehiculoCRUD(IRepository):
    def get_all(self, company_id: str, limit: int = 8, last_doc_id: str | None = None):
        query = get_db().collection("vehiculos").where("companyId", "==", company_id).order_by("__name__")

        if last_doc_id:
            last_doc = self.get_by_id(company_id, last_doc_id)
            if last_doc.exists:
                query = query.start_after_document(last_doc)

        return query.limit(limit).stream()

    def get_by_id(self, company_id: str, matricula: str):
        doc = get_db().collection("vehiculos").document(matricula.upper()).get()
        if doc.exists and (doc.to_dict() or {}).get("companyId") == company_id:
            return doc
        return get_db().collection("vehiculos").document("not_found").get()  # empty doc

    def create(self, company_id: str, matricula: str, data: dict[str, Any]) -> VehiculoSchema:
        data["companyId"] = company_id
        doc_ref = get_db().collection("vehiculos").document(matricula.upper())
        doc_ref.set(data)
        return data

    def update(self, company_id: str, matricula: str, update_data: dict[str, Any]) -> VehiculoSchema:
        doc_ref = get_db().collection("vehiculos").document(matricula.upper())
        doc = doc_ref.get()
        if doc.exists and (doc.to_dict() or {}).get("companyId") == company_id:
            doc_ref.update(update_data)
        return update_data

    def delete(self, company_id: str, matricula: str) -> None:
        doc_ref = get_db().collection("vehiculos").document(matricula.upper())
        doc = doc_ref.get()
        if doc.exists and (doc.to_dict() or {}).get("companyId") == company_id:
            doc_ref.delete()
