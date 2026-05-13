from ..firebase_config import db
from google.cloud import firestore

class CargasCRUD:
    def get_todas_las_cargas(self, company_id: str, cliente_id=None, pedido_id=None, transportista_id=None, estado=None, dt_inicio=None, dt_fin=None):
        query = db.collection_group("cargas").where("companyId", "==", company_id)
        if cliente_id:
            query = query.where("clienteId", "==", cliente_id)
        if pedido_id:
            query = query.where("pedidoId", "==", pedido_id)
        if transportista_id:
            query = query.where("transportistaId", "==", transportista_id)
        if estado:
            query = query.where("estado", "==", estado)
        if dt_inicio:
            query = query.where("fechaCarga", ">=", dt_inicio)
        if dt_fin:
            query = query.where("fechaCarga", "<=", dt_fin)
        return query.stream()

    def get_carga_doc(self, carga_id: str):
        docs = db.collection_group("cargas").where("id", "==", carga_id).get()
        if docs:
             return docs[0]
        return db.collection("cargas").document("not_found").get() # empty doc

    def get_tipos_cargas(self, company_id: str, cliente_id: str) -> list:
        return (db.collection("tipos_carga")
                .where("companyId", "==", company_id)
                .where("clienteId", "==", cliente_id)).get()

    def get_tipo_carga_by_id(self, tipo_id: str) -> list:
        return db.collection("tipos_carga").document(tipo_id).get()

    def create_carga_doc(self, payload: dict) -> str:
        # Transacción para asegurar que el contador se actualiza correctamente y no hay duplicados
        counter_ref = db.collection("counters").document("cargas")

        @firestore.transactional
        def create_in_transaction(transaction):
            snapshot = counter_ref.get(transaction=transaction)
            if snapshot.exists:
                count = snapshot.get("count") + 1
            else:
                count = 1

            transaction.set(counter_ref, {"count": count}, merge=True)

            custom_id = f"CRG-{count:03d}"
            doc_ref = db.collection("cargas").document(custom_id)
            payload["id"] = custom_id

            # Usamos set en la transacción para el nuevo documento
            transaction.set(doc_ref, payload)
            return custom_id

        return create_in_transaction(db.transaction())

    def update_carga_doc(self, carga_id: str, update_data: dict):
        docs = db.collection_group("cargas").where("id", "==", carga_id).get()
        if docs:
            docs[0].reference.update(update_data)

    def delete_carga_doc(self, carga_id: str):
        docs = db.collection_group("cargas").where("id", "==", carga_id).get()
        if docs:
            docs[0].reference.delete()

    def get_trans_doc(self, trans_id: str):
        return db.collection("users").document(trans_id).get()

    def get_cargas_count(self, company_id: str, estado: str):
        return db.collection_group('cargas').where('companyId', '==', company_id).where('estado', '==', estado).count().get()

    def get_cargas_hoy_count(self, company_id: str, sod, eod, estado=None):
        query = db.collection_group('cargas').where('companyId', '==', company_id).where('fechaDescarga', '>=', sod).where('fechaDescarga', '<=', eod).order_by('fechaDescarga')
        if estado:
            query = query.where('estado', '==', estado)
        return query.count().get()
