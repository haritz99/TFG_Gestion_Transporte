from ..firebase_config import db

class CargasCRUD:
    def get_todas_las_cargas(self, company_id: str, cliente_id=None, pedido_id=None, transportista_id=None, estado=None, dt_inicio=None, dt_fin=None):
        query = db.collection("cargas").where("companyId", "==", company_id)
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
        return db.collection("cargas").document(carga_id).get()

    def create_carga_doc(self, payload: dict) -> str:
        doc_ref = db.collection("cargas").document()
        payload["id"] = doc_ref.id
        doc_ref.set(payload)
        return doc_ref.id

    def update_carga_doc(self, carga_id: str, update_data: dict):
        db.collection("cargas").document(carga_id).update(update_data)

    def delete_carga_doc(self, carga_id: str):
        db.collection("cargas").document(carga_id).delete()

    def get_trans_doc(self, trans_id: str):
        return db.collection("users").document(trans_id).get()

    def get_cargas_count(self, company_id: str, estado: str):
        return db.collection('cargas').where('companyId', '==', company_id).where('estado', '==', estado).count().get()

    def get_cargas_hoy_count(self, company_id: str, sod, eod, estado=None):
        query = db.collection('cargas').where('companyId', '==', company_id).where('fechaDescarga', '>=', sod).where('fechaDescarga', '<=', eod).order_by('fechaDescarga')
        if estado:
            query = query.where('estado', '==', estado)
        return query.count().get()
