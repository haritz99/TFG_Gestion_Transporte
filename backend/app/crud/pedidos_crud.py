from ..firebase_config import db
from google.cloud import firestore

class PedidosCRUD:
    def get_todos_los_pedidos(self, company_id: str, cliente_id=None, estado=None, dt_inicio=None, dt_fin=None):
        query = db.collection("pedidos").where("companyId", "==", company_id)
        if cliente_id:
            query = query.where("clienteId", "==", cliente_id)
        if estado:
            query = query.where("estado", "==", estado)
        if dt_inicio:
            query = query.where("fechaCarga", ">=", dt_inicio)
        if dt_fin:
            query = query.where("fechaCarga", "<=", dt_fin)
        return query.stream()

    def get_pedido_doc(self, pedido_id: str):
        return db.collection("pedidos").document(pedido_id).get()

    def create_pedido_doc(self, payload: dict) -> str:
        # Transacción para asegurar que el contador se actualiza correctamente y no hay duplicados
        counter_ref = db.collection("counters").document("pedidos")

        @firestore.transactional
        def create_in_transaction(transaction):
            snapshot = counter_ref.get(transaction=transaction)
            if snapshot.exists:
                count = snapshot.get("count") + 1
            else:
                count = 1

            transaction.set(counter_ref, {"count": count}, merge=True)

            custom_id = f"PED-{count:03d}"
            doc_ref = db.collection("pedidos").document(custom_id)
            payload["id"] = custom_id

            transaction.set(doc_ref, payload)
            return custom_id

        return create_in_transaction(db.transaction())

    def delete_pedido_y_cargas(self, pedido_ref, cargas_refs):
        batch = db.batch()
        for c_ref in cargas_refs:
            batch.delete(c_ref)
        batch.delete(pedido_ref)
        batch.commit()

    def get_pedido_ref(self, pedido_id: str):
        return db.collection("pedidos").document(pedido_id)

    def get_carga_ref(self, carga_id: str):
        return db.collection("cargas").document(carga_id)
