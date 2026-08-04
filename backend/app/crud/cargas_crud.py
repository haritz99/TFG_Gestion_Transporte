from typing import Any

from google.cloud import firestore
from app.firebase_config import get_db
from app.interfaces.i_cargas_repository import ICargasRepository


class CargasCRUD(ICargasRepository):
    def get_all(self, company_id: str, cliente_id=None, pedido_id=None, transportista_id=None, estado=None, dt_inicio=None, dt_fin=None):
        query = get_db().collection_group("cargas").where("companyId", "==", company_id)
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

    def get_tipos_cargas(self, company_id: str, cliente_id: str) -> list:
        return (get_db().collection("tipos_carga")
                .where("companyId", "==", company_id)
                .where("clienteId", "==", cliente_id)).get()

    def create_tipo_carga(self, tipo_carga_data: dict):
        doc_ref = get_db().collection("tipos_carga").document()
        tipo_carga_data["id"] = doc_ref.id
        doc_ref.set(tipo_carga_data)
        return tipo_carga_data

    def get_tipo_carga_by_id(self, company_id: str, tipo_id: str) -> list:
        doc = get_db().collection("tipos_carga").document(tipo_id).get()
        if doc.exists and (doc.to_dict() or {}).get("companyId") == company_id:
            return doc
        return get_db().collection("tipos_carga").document("not_found").get()  # empty doc

    def get_cargas_count(self, company_id: str, estado: str, inicio=None, fin=None):
        query = get_db().collection_group('cargas').where('companyId', '==', company_id).where('estado', '==', estado)
        if inicio is not None:
            query = query.where('fechaCarga', '>=', inicio)
        if fin is not None:
            query = query.where('fechaCarga', '<=', fin)
        return query.count().get()

    def get_cargas_hoy_count(self, company_id: str, sod, eod, estado=None):
        query = get_db().collection_group('cargas').where('companyId', '==', company_id).where('fechaDescarga', '>=', sod).where('fechaDescarga', '<=', eod).order_by('fechaDescarga')
        if estado:
            query = query.where('estado', '==', estado)
        return query.count().get()

    def get_carga_ref(self, company_id: str, carga_id: str):
        docs = get_db().collection_group("cargas").where("companyId", "==", company_id).where("id", "==", carga_id).limit(1).get()
        if docs:
            return docs[0].reference
        return None

    def get_batch(self):
        return get_db().batch()

    def get_cargas_by_ids(self, company_id: str, ids: list[str]):
        if not ids:
            return []
        docs = []
        for i in range(0, len(ids), 30):
            chunk = ids[i:i+30]
            results = get_db().collection_group("cargas").where("companyId", "==", company_id).where("id", "in", chunk).get()
            docs.extend(results)
        return docs

    def create(self, company_id: str, data: dict[str, Any]) -> str:
        data["companyId"] = company_id
        # Transacción para asegurar que el contador se actualiza correctamente y no hay duplicados
        counter_ref = get_db().collection("counters").document("cargas")

        @firestore.transactional
        def create_in_transaction(transaction):
            snapshot = counter_ref.get(transaction=transaction)
            if snapshot.exists:
                count = snapshot.get("count") + 1
            else:
                count = 1

            transaction.set(counter_ref, {"count": count}, merge=True)

            custom_id = f"CRG-{count:03d}"
            doc_ref = get_db().collection("cargas").document(custom_id)
            data["id"] = custom_id

            # Usamos set en la transacción para el nuevo documento
            transaction.set(doc_ref, data)
            return custom_id

        return create_in_transaction(get_db().transaction())

    def get_by_id(self, company_id: str, carga_id: str):
        docs = get_db().collection_group("cargas").where("companyId", "==", company_id).where("id", "==", carga_id).limit(1).get()
        if docs:
            return docs[0]
        return get_db().collection("cargas").document("not_found").get()  # empty doc

    def update(self, company_id: str, carga_id: str, update_data: dict) -> None:
        docs = get_db().collection_group("cargas").where("companyId", "==", company_id).where("id", "==", carga_id).get()
        if docs:
            docs[0].reference.update(update_data)

    def delete(self, company_id: str, carga_id: str) -> None:
        docs = get_db().collection_group("cargas").where("companyId", "==", company_id).where("id", "==", carga_id).get()
        if docs:
            docs[0].reference.delete()
