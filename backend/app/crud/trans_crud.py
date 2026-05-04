from .user_crud import UserCRUD
from ..firebase_config import db
from google.cloud.firestore_v1.base_document import DocumentSnapshot

class TransCRUD:
    def get_all(self, company_id: str, solodis: bool, limit: int = 8, last_doc_id: str | None = None, user_crud: UserCRUD = None):
        query = (
            db.collection("users")
            .where("companyId", "==", company_id)
            .where("rol", "array_contains", "transportista")
            .order_by("__name__")
        )

        if solodis:
            query = query.where("vehiculoId", "==", None)

        if last_doc_id and user_crud:
            last_doc = user_crud.get_by_id(uid = last_doc_id)
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

    def get_vehiculo(self, vehiculo_id: str) -> DocumentSnapshot:
        vehiculo_ref = db.collection("vehiculos").document(vehiculo_id)
        return vehiculo_ref.get()

    def update_vehiculo(self, vehiculo_id: str, data: dict) -> None:
        vehiculo_ref = db.collection("vehiculos").document(vehiculo_id)
        vehiculo_ref.update(data)
