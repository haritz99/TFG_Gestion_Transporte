from ..firebase_config import db

class VehiculoCRUD:
    def get_all(self, company_id: str, limit: int = 8, last_doc_id: str | None = None):
        query = db.collection("vehiculos").where("companyId", "==", company_id).order_by("__name__")

        if last_doc_id:
            last_doc = self.get_by_id(last_doc_id)
            if last_doc.exists:
                query = query.start_after_document(last_doc)

        return query.limit(limit).stream()

    def get_by_id(self, matricula: str):
        return db.collection("vehiculos").document(matricula.upper()).get()


    def commit_batch(self, batch):
        batch.commit()

    def set_vehiculo(self, matricula: str, vehiculo_data: dict):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        doc_ref.set(doc_ref, vehiculo_data)

    def update_vehiculo(self, matricula: str, vehiculo_data: dict):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        doc_ref.update(doc_ref, vehiculo_data)

    def delete_vehiculo(self, matricula: str):
        doc_ref = db.collection("vehiculos").document(matricula.upper())
        doc_ref.delete(doc_ref)
