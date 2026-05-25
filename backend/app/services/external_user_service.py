from fastapi import Depends, HTTPException
from datetime import datetime
from firebase_admin import auth as firebase_auth
from ..crud.pedidos_crud import PedidosCRUD
from ..firebase_config import db
from ..schemas.external_user import ExternalUserSchema
from ..crud.user_crud import UserCRUD
from ..crud.cargas_crud import CargasCRUD
from ..schemas.pedido import EstadoPedido


class ExternalUserService:
    def __init__(self, user_crud: UserCRUD = Depends(UserCRUD),
                 pedidos_crud: PedidosCRUD = Depends(PedidosCRUD),
                 cargas_crud: CargasCRUD = Depends(CargasCRUD)):
        self._user_crud = user_crud
        self._pedidos_crud = pedidos_crud   # para eliminacion cascada pedidos
        self._cargas_crud = cargas_crud     # para eliminacion cascada cargas

    def fetch_external_users(self, company_id: str) -> list[ExternalUserSchema]:
        """
        Obtiene todos los usuarios externos que esten activos, se usa en la lista de Invite.
        """
        docs = self._user_crud.get_all_external_users(company_id)
        users = []
        for doc in docs:
            data = doc.to_dict()
            if not data:
                continue
            data["uid"] = doc.id
            users.append(ExternalUserSchema(**data))

        users.sort(key=lambda x: x.createdAt or datetime.min, reverse=True)
        return users

    def soft_delete_external_user(self, uid: str, company_id: str):
        """
        Realiza un soft delete de un usuario externo (cliente o subcontratado).
        """
        cliente_doc = self._user_crud.get_cliente_by_id(uid)
        sub_doc = self._user_crud.get_subcontratado_by_id(uid)

        if cliente_doc.exists:
            data = cliente_doc.to_dict()
            if data.get("companyId") != company_id:
                raise HTTPException(status_code=403, detail="No autorizado")
            self._user_crud.update_cliente(uid, {"activo": False, "updatedAt": datetime.now()})
            try:
                firebase_auth.update_user(uid, disabled=True)
            except Exception:
                pass
            return

        if sub_doc.exists:
            data = sub_doc.to_dict()
            if data.get("companyId") != company_id:
                raise HTTPException(status_code=403, detail="No autorizado")
            self._user_crud.update_subcontratado(uid, {"activo": False, "updatedAt": datetime.now()})
            try:
                firebase_auth.update_user(uid, disabled=True)
            except Exception:
                pass
            return

        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    def delete_cliente_cascada(self, cliente_id: str, company_id: str):
        """
        Borra un cliente y todos sus pedidos/cargas asociados.
        """
        cliente_ref = db.collection("clientes").document(cliente_id)
        cliente_doc = cliente_ref.get()

        if not cliente_doc.exists:
            raise HTTPException(status_code=404, detail="Cliente no encontrado")

        if cliente_doc.to_dict().get("companyId") != company_id:
            raise HTTPException(status_code=403, detail="No autorizado")
        pedidos = list(self._pedidos_crud.get_todos_los_pedidos(company_id=company_id, cliente_id=cliente_id))
        
        for p_doc in pedidos:
            estado = p_doc.get("estado")
            if estado in {EstadoPedido.PLANIFICADO, EstadoPedido.EN_PROGRESO}:
                raise HTTPException(status_code=400, detail="No se puede eliminar: tiene pedidos activos")

        batch = db.batch()
        for p_doc in pedidos:
            # Borrar cargas del pedido
            cargas = self._cargas_crud.get_todas_las_cargas(company_id=company_id, pedido_id=p_doc.id)
            for c_doc in cargas:
                batch.delete(c_doc.reference)
            
            # Borrar pedido
            batch.delete(p_doc.reference)

        batch.delete(cliente_ref)
        batch.commit()