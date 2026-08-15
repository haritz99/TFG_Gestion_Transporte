from abc import ABC, abstractmethod
from typing import Any


class ICartaPorteService(ABC):

    @abstractmethod
    def get_carta_porte_template_data(
        self,
        carga_id: str,
        company_id: str
    ) -> dict[str, Any]:
        pass

    @abstractmethod
    def generar_carta_porte_pdf(
        self,
        carga_id: str,
        company_id: str
    ) -> str:
        pass

    @abstractmethod
    def eliminar_carta_porte_pdf(
        self,
        company_id: str,
        carga_id: str
    ) -> None:
        pass
