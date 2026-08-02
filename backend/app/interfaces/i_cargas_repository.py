from abc import abstractmethod
from typing import Any

from app.interfaces.i_repository import IRepository


class ICargasRepository(IRepository):

    @abstractmethod
    def get_all(self, company_id: str, cliente_id=None, pedido_id=None, transportista_id=None, estado=None, dt_inicio=None, dt_fin=None):
        pass

    @abstractmethod
    def get_tipos_cargas(self, company_id: str, cliente_id: str):
        pass

    @abstractmethod
    def create_tipo_carga(self, tipo_carga_data: dict):
        pass

    @abstractmethod
    def get_tipo_carga_by_id(self, tipo_id: str):
        pass

    @abstractmethod
    def get_cargas_count(self, company_id: str, estado: str, inicio=None, fin=None):
        pass

    @abstractmethod
    def get_cargas_hoy_count(self, company_id: str, sod, eod, estado=None):
        pass

    @abstractmethod
    def get_carga_ref(self, carga_id: str):
        pass

    @abstractmethod
    def get_batch(self):
        pass

    @abstractmethod
    def get_cargas_by_ids(self, company_id: str, ids: list[str]) -> list[Any]:
        pass
