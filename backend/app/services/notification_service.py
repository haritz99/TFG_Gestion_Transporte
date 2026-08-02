from firebase_admin import messaging
from fastapi import Depends, HTTPException
from app.dependencies.repositories import get_user_repository
from app.interfaces.i_user_repository import IUserRepository



class NotificacionService:

    def __init__(self, user_crud: IUserRepository = Depends(get_user_repository)):
        self._user_crud = user_crud

    def _get_token(self, user_id: str, roles: list[str], company_id: str | None = None) -> str | None:
        if "encargado" in roles or "transportista" in roles:
            doc = self._user_crud.get_by_id(company_id, user_id)
        elif "cliente" in roles:  # cargador
            doc = self._user_crud.get_cliente_by_id(user_id)
        elif "subcontratado" in roles:
            doc = self._user_crud.get_subcontratado_by_id(user_id)
        else:
            return None

        if not doc or not doc.exists:
            return None
        return doc.to_dict().get("fcmToken")

    def guardar_fcm_token(self, company_id: str, uid: str, roles: list[str], token: str) -> None:
        update = {"fcmToken": token}
        if "encargado" in roles or "transportista" in roles:
            self._user_crud.update(company_id, uid, update)
        elif "cliente" in roles: # cargador
            self._user_crud.update_cliente(uid, update)
        elif "subcontratado" in roles:
            self._user_crud.update_subcontratado(uid, update)
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Ningún rol compatible encontrado en la lista: {roles}"
    )

    @staticmethod
    def enviar(token: str, titulo: str, cuerpo: str, data: dict = None):
        message = messaging.Message(
            notification=messaging.Notification(title=titulo, body=cuerpo),
            data=data or {},
            token=token,
        )
        try:
            print("Enviando mensaje con payload:", message)
            messaging.send(message)
        except Exception as e:
            print(f"Error enviando notificación: {e}")


    def notificar(self, user_id: str, roles: list[str], titulo: str, cuerpo: str, data: dict = None, company_id: str | None = None):
        print("entra en notificar")
        token = self._get_token(user_id, roles, company_id)
        if token:
            print(f"Enviando notificación al token: {token}")
            self.enviar(token, titulo, cuerpo, data)
            print("se supone que se envia")