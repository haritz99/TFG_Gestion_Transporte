from abc import ABC, abstractmethod
from collections.abc import Iterable
from typing import Any


class IRepository(ABC):
    @abstractmethod
    def create(self, company_id: str, data: dict[str, Any], *args: Any, **kwargs: Any) -> Any:
        """Crea un nuevo documento de la entidad dentro del tenant."""

    @abstractmethod
    def get_all(self, company_id: str, *args: Any, **kwargs: Any) -> Iterable[Any]:
        """Devuelve los documentos de la entidad de un tenant."""

    @abstractmethod
    def get_by_id(self, company_id: str, entity_id: str, *args: Any, **kwargs: Any) -> Any:
        """Devuelve un documento de la entidad por su id dentro del tenant."""

    @abstractmethod
    def update(self, company_id: str, entity_id: str, update_data: dict[str, Any], *args: Any, **kwargs: Any) -> Any:
        """Actualiza un documento de la entidad por su id dentro del tenant."""

    @abstractmethod
    def delete(self, company_id: str, entity_id: str, *args: Any, **kwargs: Any) -> None:
        """Elimina un documento de la entidad por su id dentro del tenant."""
