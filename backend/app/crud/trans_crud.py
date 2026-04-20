from ..firebase_config import db
from google.cloud.firestore_v1.base_document import DocumentSnapshot

class TransCRUD:
    def get_all(self, company_id: str, solodis: bool, limit: int = 8, last_doc_id: str | None = None):
        query = (
            db.collection("users")
            .where("companyId", "==", company_id)
            .where("rol", "array_contains", "transportista")
            .order_by("__name__")
        )

        if solodis:
            query = query.where("vehiculoId", "==", None)

        if last_doc_id:
            last_doc = self.get_by_id(last_doc_id)
            if last_doc.exists:
                query = query.start_after(last_doc)

        return query.limit(limit).stream()

    def get_count(self, company_id: str):
        users_ref = db.collection("users")
        query_ref = (
            users_ref
            .where("companyId", "==", company_id)
            .where("rol", "array_contains", "transportista")
        )
        return query_ref.count().get()

    def get_count_by_estado(self, company_id: str, estado: str):
        users_ref = db.collection("users")
        query_ref = (
            users_ref
            .where("companyId", "==", company_id)
            .where("rol", "array_contains", "transportista")
            .where("estado", "==", estado)
        )
        return query_ref.count().get()
    def get_by_id(self, uid: str) -> DocumentSnapshot:
        doc_ref = db.collection("users").document(uid)
        return doc_ref.get()

    def create(self, uid: str, user_dict: dict) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.set(user_dict)

    def update(self, uid: str, update_dict: dict) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.update(update_dict)

    def delete(self, uid: str) -> None:
        doc_ref = db.collection("users").document(uid)
        doc_ref.delete()

    def get_vehiculo(self, vehiculo_id: str) -> DocumentSnapshot:
        vehiculo_ref = db.collection("vehiculo").document(vehiculo_id)
        return vehiculo_ref.get()

    def update_vehiculo(self, vehiculo_id: str, data: dict) -> None:
        vehiculo_ref = db.collection("vehiculo").document(vehiculo_id)
        vehiculo_ref.update(data)
