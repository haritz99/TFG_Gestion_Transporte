from typing import Any

from app.firebase_config import get_db
from app.interfaces.i_company_repository import ICompanyRepository


class CompanyCRUD(ICompanyRepository):
    def create(self, company_dict: dict) -> str:
        doc_ref = get_db().collection("empresas").document()
        doc_ref.set(company_dict)
        return doc_ref.id

    def get_by_id(self, company_id: str) -> Any:
        return get_db().collection("empresas").document(company_id).get()

    def update(self, company_id: str, update_data: dict[str, Any]) -> None:
        doc_ref = get_db().collection("empresas").document(company_id)
        doc_ref.update(update_data)
