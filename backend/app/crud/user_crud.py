from app.firebase_config import get_db
from google.cloud.firestore_v1.base_document import DocumentSnapshot
from app.interfaces.i_user_repository import IUserRepository

class UserCRUD(IUserRepository):
    def get_by_id(self, company_id: str, uid: str) -> DocumentSnapshot:
        doc_ref = get_db().collection("users").document(uid)
        return doc_ref.get()

    def get_cliente_by_id(self, uid: str) -> DocumentSnapshot:
        doc_ref = get_db().collection("clientes").document(uid)
        return doc_ref.get()

    def get_subcontratado_by_id(self, uid: str) -> DocumentSnapshot:
        doc_ref = get_db().collection("subcontratados").document(uid)
        return doc_ref.get()

    def create(company_id: str, uid: str, user_dict: dict) -> None:
        doc_ref = get_db().collection("users").document(uid)
        doc_ref.set(user_dict)

    def update(self, company_id: str, uid: str, update_dict: dict) -> None:
        doc_ref = get_db().collection("users").document(uid)
        doc_ref.update(update_dict)

    def delete(self, company_id: str, uid: str) -> None:
        doc_ref = get_db().collection("users").document(uid)
        doc_ref.delete()

    def create_cliente(self, uid: str, cliente_dict: dict) -> None:
        get_db().collection("clientes").document(uid).set(cliente_dict)

    def create_subcontratado(self, uid: str, subcontratado_dict: dict) -> None:
        get_db().collection("subcontratados").document(uid).set(subcontratado_dict)

    def update_cliente(self, uid: str, cliente_dict: dict) -> None:
        get_db().collection("clientes").document(uid).update(cliente_dict)

    def update_subcontratado(self, uid: str, cliente_dict: dict) -> None:
        get_db().collection("subcontratados").document(uid).update(cliente_dict)

    def get_all_external_users(self, company_id: str) -> list[DocumentSnapshot]:
        """
        Obtiene todos los clientes y subcontratados activos de una compañía.
        """
        clientes = get_db().collection("clientes").where("companyId", "==", company_id).where("activo", "==", True).stream()

        subcontratados = get_db().collection("subcontratados").where("companyId", "==", company_id).where("activo", "==", True).stream()

        # Combinamos ambos streams en una lista
        all_users = list(clientes) + list(subcontratados)
        return all_users

    def get_all(self, company_id: str, solodis: bool, limit: int = 8, last_doc_id: str | None = None):
        query = (
            get_db().collection("users")
            .where("companyId", "==", company_id)
            .where("rol", "array_contains", "transportista")
            .order_by("__name__")
        )

        if solodis:
            query = query.where("vehiculoId", "==", None)

        if last_doc_id:
            last_doc = self.get_by_id(company_id, uid=last_doc_id)
            if last_doc.exists:
                query = query.start_after(last_doc)

        return query.limit(limit).stream()
