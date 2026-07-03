from app.firebase_config import get_db
from google.cloud import firestore

class PedidosCRUD:
    def get_todos_los_pedidos(self, company_id: str, cliente_id=None, estado=None, dt_inicio=None, dt_fin=None):
        query = get_db().collection("pedidos").where("companyId", "==", company_id)
        if cliente_id:
            query = query.where("clienteId", "==", cliente_id)
        if estado:
            query = query.where("estado", "==", estado)
        if dt_inicio:
            query = query.where("fechaCarga", ">=", dt_inicio)
        if dt_fin:
            query = query.where("fechaCarga", "<=", dt_fin)
        return query.stream()

    def get_all(self, refs):
        if not refs:
            return []
        return list(get_db().get_all(refs))

    def get_pedido_doc(self, pedido_id: str):
        return get_db().collection("pedidos").document(pedido_id).get()


    def create_pedido_con_cargas(self, pedido_payload: dict, cargas_payloads: list[dict]) -> dict:
        counter_pedido_ref = get_db().collection("counters").document("pedidos")
        counter_cargas_ref = get_db().collection("counters").document("cargas")

        @firestore.transactional
        def create_in_transaction(transaction):
            snap_pedido = counter_pedido_ref.get(transaction=transaction)
            pedido_count = snap_pedido.get("count") + 1 if snap_pedido.exists else 1

            snap_cargas = counter_cargas_ref.get(transaction=transaction)
            cargas_count = snap_cargas.get("count") if snap_cargas.exists else 0

            # Update counters
            transaction.set(counter_pedido_ref, {"count": pedido_count}, merge=True)
            transaction.set(counter_cargas_ref, {"count": cargas_count + len(cargas_payloads)}, merge=True)

            # Create Pedido
            pedido_id = f"PED-{pedido_count:03d}"
            pedido_ref = get_db().collection("pedidos").document(pedido_id)
            pedido_payload["id"] = pedido_id
            transaction.set(pedido_ref, pedido_payload)

            # Create Cargas as subcollection
            cargas_creadas = []
            for i, carga_payload in enumerate(cargas_payloads, start=1):
                carga_id = f"CRG-{cargas_count + i:03d}"
                carga_ref = pedido_ref.collection("cargas").document(carga_id)
                carga_payload["id"] = carga_id
                carga_payload["pedidoId"] = pedido_id
                transaction.set(carga_ref, carga_payload)
                cargas_creadas.append(carga_payload)

            return {
                "pedidoId": pedido_id,
                "cargas": cargas_creadas
            }

        return create_in_transaction(get_db().transaction())

    def delete_pedido_y_cargas(self, pedido_ref, cargas_refs):
        batch = get_db().batch()
        for c_ref in cargas_refs:
            batch.delete(c_ref)
        batch.delete(pedido_ref)
        batch.commit()

    def get_pedido_ref(self, pedido_id: str):
        return get_db().collection("pedidos").document(pedido_id)

    def get_carga_ref(self, carga_id: str):
        return get_db().collection("cargas").document(carga_id)
