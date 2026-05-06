from ..firebase_config import db
from google.cloud.firestore_v1.base_document import DocumentSnapshot

class UserCRUD:
    def get_by_id(self, uid: str) -> DocumentSnapshot:
        doc_ref = db.collection("users").document(uid)
        return doc_ref.get()

    @staticmethod
    def create(uid: str, user_dict: dict) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.set(user_dict)

    def update(self, uid: str, update_dict: dict) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.update(update_dict)

    def delete(self, uid: str) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.delete()

    def create_cliente(self, uid: str, cliente_dict: dict) -> None:
        db.collection("clientes").document(uid).set(cliente_dict)

    def create_subcontratado(self, uid: str, subcontratado_dict: dict) -> None:
        db.collection("subcontratados").document(uid).set(subcontratado_dict)

    @staticmethod
    def get_all_external_users(company_id: str) -> list[DocumentSnapshot]:
        """
        Obtiene todos los clientes y subcontratados de una compañía.
        """
        clientes = db.collection("clientes").where("companyId", "==", company_id).stream()
        subcontratados = db.collection("subcontratados").where("companyId", "==", company_id).stream()

        # Combinamos ambos streams en una lista
        all_users = list(clientes) + list(subcontratados)
        return all_users
