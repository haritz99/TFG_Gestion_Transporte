from typing import List
from pydantic import Field

from .base import FirestoreSchema
from .pedido import PedidoSchema


class ClienteScheema(FirestoreSchema):
    nombreComercial: str = Field(..., min_length=1)
    pedidos: List[PedidoSchema] = Field(..., min_length=1)
    companyId: str = Field(..., min_length=1)
