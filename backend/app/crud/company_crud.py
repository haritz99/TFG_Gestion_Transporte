from app.firebase_config import get_db

class CompanyCRUD:
    @staticmethod
    def create(company_dict: dict) -> str:
        doc_ref = get_db().collection("empresas").document()
        doc_ref.set(company_dict)
        return doc_ref.id

    @staticmethod
    def get_by_id(company_id: str):
        return get_db().collection("empresas").document(company_id).get()

    def update(self, company_id, param):
        doc_ref = get_db().collection("empresas").document(company_id)
        doc_ref.update(param)

