from fastapi import Depends

from app.crud.cargas_crud import CargasCRUD
from app.crud.company_crud import CompanyCRUD
from app.crud.pedidos_crud import PedidosCRUD
from app.crud.user_crud import UserCRUD
from app.crud.vehiculos_crud import VehiculoCRUD
from app.interfaces.i_cargas_repository import ICargasRepository
from app.interfaces.i_company_repository import ICompanyRepository
from app.interfaces.i_pedidos_repository import IPedidosRepository
from app.interfaces.i_repository import IRepository
from app.interfaces.i_user_repository import IUserRepository


def get_cargas_repository(
    crud: CargasCRUD = Depends(CargasCRUD),
) -> ICargasRepository:
    return crud


def get_pedidos_repository(
    crud: PedidosCRUD = Depends(PedidosCRUD),
) -> IPedidosRepository:
    return crud


def get_user_repository(
    crud: UserCRUD = Depends(UserCRUD),
) -> IUserRepository:
    return crud


def get_company_repository(
    crud: CompanyCRUD = Depends(CompanyCRUD),
) -> ICompanyRepository:
    return crud


def get_vehiculos_repository(
    crud: VehiculoCRUD = Depends(VehiculoCRUD),
) -> IRepository:
    return crud
