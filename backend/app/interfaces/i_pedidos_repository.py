from abc import abstractmethod

from app.interfaces.i_repository import IRepository


class IPedidosRepository(IRepository):

    @abstractmethod
    def get_all(self, company_id: str, cliente_id=None, estado=None, dt_inicio=None, dt_fin=None):
        pass

    @abstractmethod
    def get_pedidos_by_refs(self, company_id: str, refs):
        pass

    @abstractmethod
    def get_pedido_ref(self, pedido_id: str):
        pass

    @abstractmethod
    def get_carga_ref(self, carga_id: str):
        pass
