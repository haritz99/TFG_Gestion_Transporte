from ..firebase_config import db

class CompanyCRUD:
    @staticmethod
    def create(company_dict: dict) -> str:
        doc_ref = db.collection("empresas").document()
        doc_ref.set(company_dict)
        return doc_ref.id

    @staticmethod
    def get_by_id(company_id: str):
        return db.collection("empresas").document(company_id).get()

    def update(self, company_id, param):
        doc_ref = db.collection("empresas").document(company_id)
        doc_ref.update(param)

