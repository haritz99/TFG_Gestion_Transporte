from fastapi import Depends

from app.interfaces.i_carta_porte_service import ICartaPorteService
from app.services.carta_porte_service import CartaPorteService


def get_carta_porte_service(
    service: CartaPorteService = Depends(CartaPorteService),
) -> ICartaPorteService:
    return service
