from firebase_admin import messaging
from fastapi import Depends, HTTPException
from app.crud.user_crud import UserCRUD



class NotificacionService:

    def __init__(self, user_crud: UserCRUD = Depends(UserCRUD)):
        self._user_crud = user_crud

    def _get_token(self, user_id: str, role: str) -> str | None:
        match role:
            case "encargado" | "transportista":
                doc = self._user_crud.get_by_id(user_id)
            case "cargador":
                doc = self._user_crud.get_cliente_by_id(user_id)
            case "subcontratado":
                doc = self._user_crud.get_subcontratado_by_id(user_id)
            case _:
                return None

        if not doc.exists:
            return None
        return doc.to_dict().get("fcmToken")

    def guardar_fcm_token(self, uid: str, role: str, token: str) -> None:
        update = {"fcmToken": token}
        match role:
            case "encargado" | "transportista":
                self._user_crud.update(uid, update)
            case "cargador":
                self._user_crud.update_cliente(uid, update)
            case "subcontratado":
                self._user_crud.update_subcontratado(uid, update)
            case _:
                raise HTTPException(status_code=400, detail=f"Rol desconocido: {role}")

    @staticmethod
    def enviar(token: str, titulo: str, cuerpo: str, data: dict = None):
        message = messaging.Message(
            notification=messaging.Notification(title=titulo, body=cuerpo),
            data=data or {},
            token=token,
        )
        try:
            messaging.send(message)
        except Exception as e:
            print(f"Error enviando notificación: {e}")


    def notificar(self, user_id: str, role: str, titulo: str, cuerpo: str, data: dict = None):
        token = self._get_token(user_id, role)
        if token:
            self.enviar(token, titulo, cuerpo, data)