from ..firebase_config import db

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
        doc_ref = db.collection("pedidos").document()
        payload["id"] = doc_ref.id
        doc_ref.set(payload)
        return doc_ref.id

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
