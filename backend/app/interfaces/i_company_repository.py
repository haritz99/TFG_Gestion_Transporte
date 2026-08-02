from abc import ABC, abstractmethod
from typing import Any


class ICompanyRepository(ABC):

    @abstractmethod
    def create(self, company_dict: dict) -> str:
        pass

    @abstractmethod
    def get_by_id(self, company_id: str) -> Any:
        pass

    @abstractmethod
    def update(self, company_id: str, update_data: dict[str, Any]) -> None:
        pass
