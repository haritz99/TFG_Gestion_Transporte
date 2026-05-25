from ..firebase_config import db

class VehiculoCRUD:
    def get_all(self, company_id: str, limit: int = 8, last_doc_id: str | None = None):
        query = db.collection("vehiculos").where("companyId", "==", company_id).order_by("__name__")

        if last_doc_id:
            last_doc = self.get_by_id(last_doc_id)
            if last_doc.exists:
                query = query.start_after_document(last_doc)

        return query.limit(limit).stream()

    def get_count(self, company_id: str):
        return db.collection("vehiculos").where("companyId", "==", company_id).count().get()

    def get_count_by_estado(self, company_id: str, estado: str):
        return db.collection("vehiculos").where("companyId", "==", company_id).where("estado", "==", estado).count().get()

    def get_by_id(self, matricula: str):
        return db.collection("vehiculos").document(matricula.upper()).get()

    def get_user_by_id(self, uid: str):
        return db.collection("users").document(uid).get()

    def get_batch(self):
        return db.batch()

    def commit_batch(self, batch):
        batch.commit()

    def set_vehiculo(self, batch, matricula: str, vehiculo_data: dict):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        batch.set(doc_ref, vehiculo_data)

    def update_vehiculo(self, batch, matricula: str, vehiculo_data: dict):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        batch.update(doc_ref, vehiculo_data)

    def delete_vehiculo(self, batch, matricula: str):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        batch.delete(doc_ref)

    def update_user_vehiculo_id(self, batch, user_id: str, vehiculo_id: str | None):
        user_ref = db.collection("users").document(user_id)
        batch.update(user_ref, {"vehiculoId": vehiculo_id})
