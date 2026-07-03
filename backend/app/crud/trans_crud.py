from .user_crud import UserCRUD
from app.firebase_config import get_db

class TransCRUD:
    def get_all(self, company_id: str, solodis: bool, limit: int = 8, last_doc_id: str | None = None, user_crud: UserCRUD = None):
        query = (
            get_db().collection("users")
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
