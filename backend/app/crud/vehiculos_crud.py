from ..firebase_config import db

class VehiculoCRUD:
    def get_all(self, company_id: str, limit: int = 8, last_doc_id: str | None = None):
        query = db.collection("vehiculos").where("companyId", "==", company_id).order_by("__name__")

        if last_doc_id:
            last_doc = self.get_by_id(last_doc_id)
            if last_doc.exists:
                query = query.start_after(last_doc)

        return query.limit(limit).stream()

    @staticmethod
    def get_count(company_id: str):
        return db.collection("vehiculos").where("companyId", "==", company_id).count().get()

    @staticmethod
    def get_count_by_estado(company_id: str, estado: str):
        return db.collection("vehiculos").where("companyId", "==", company_id).where("estado", "==", estado).count().get()

    @staticmethod
    def get_by_id(matricula: str):
        return db.collection("vehiculos").document(matricula.upper()).get()

    @staticmethod
    def get_user_by_id(uid: str):
        return db.collection("users").document(uid).get()

    @staticmethod
    def get_batch():
        return db.batch()

    @staticmethod
    def commit_batch(batch):
        batch.commit()

    @staticmethod
    def set_vehiculo(batch, matricula: str, vehiculo_data: dict):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        batch.set(doc_ref, vehiculo_data)

    @staticmethod
    def update_vehiculo(batch, matricula: str, vehiculo_data: dict):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        batch.update(doc_ref, vehiculo_data)

    @staticmethod
    def delete_vehiculo(batch, matricula: str):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        batch.delete(doc_ref)

    @staticmethod
    def update_user_vehiculo_id(batch, user_id: str, vehiculo_id: str | None):
        user_ref = db.collection("users").document(user_id)
        batch.update(user_ref, {"vehiculoId": vehiculo_id})
