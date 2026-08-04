from abc import abstractmethod

from app.interfaces.i_repository import IRepository


class IUserRepository(IRepository):

    @abstractmethod
    def get_cliente_by_id(self, company_id: str, uid: str):
        pass

    @abstractmethod
    def get_subcontratado_by_id(self, company_id: str, uid: str):
        pass

    @abstractmethod
    def create_cliente(self, uid: str, cliente_dict: dict) -> None:
        pass

    @abstractmethod
    def create_subcontratado(self, uid: str, subcontratado_dict: dict) -> None:
        pass

    @abstractmethod
    def update_cliente(self, company_id: str, uid: str, cliente_dict: dict) -> None:
        pass

    @abstractmethod
    def update_subcontratado(self, company_id: str, uid: str, cliente_dict: dict) -> None:
        pass

    @abstractmethod
    def get_all_external_users(self, company_id: str):
        pass

    @abstractmethod
    def get_all(self, company_id: str, solodis: bool, limit: int = 8, last_doc_id: str | None = None):
        pass
