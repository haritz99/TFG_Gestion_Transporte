from ..firebase_config import db
from google.cloud.firestore_v1.base_document import DocumentSnapshot

class UserCRUD:
    @staticmethod
    def get_by_id(uid: str) -> DocumentSnapshot:
        doc_ref = db.collection("users").document(uid)
        return doc_ref.get()

    @staticmethod
    def create(uid: str, user_dict: dict) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.set(user_dict)

    @staticmethod
    def update(uid: str, update_dict: dict) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.update(update_dict)

    @staticmethod
    def delete(uid: str) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.delete()

    @staticmethod
    def create_cliente(uid: str, cliente_dict: dict) -> None:
        db.collection("clientes").document(uid).set(cliente_dict)

    @staticmethod
    def create_subcontratado(uid: str, subcontratado_dict: dict) -> None:
        db.collection("subcontratados").document(uid).set(subcontratado_dict)
