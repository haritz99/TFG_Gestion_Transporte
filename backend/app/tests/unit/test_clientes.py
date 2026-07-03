from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException

from app.schemas.pedido import EstadoPedido
from app.services import external_user_service as external_user_service_module
from app.services.external_user_service import ExternalUserService


@pytest.fixture
def mock_user_crud():
    return MagicMock(name="UserCRUD")


@pytest.fixture
def mock_pedidos_crud():
    return MagicMock(name="PedidosCRUD")


@pytest.fixture
def mock_cargas_crud():
    return MagicMock(name="CargasCRUD")


@pytest.fixture
def mock_db(monkeypatch):
    mock = MagicMock(name="db")
    monkeypatch.setattr(external_user_service_module, "db", mock)
    return mock


@pytest.fixture
def service(mock_user_crud, mock_pedidos_crud, mock_cargas_crud):
    return ExternalUserService(
        user_crud=mock_user_crud,
        pedidos_crud=mock_pedidos_crud,
        cargas_crud=mock_cargas_crud,
    )


def test_delete_cliente_cascada_not_found(service, mock_db):
    mock_cliente_doc = MagicMock(exists=False)
    mock_db.collection.return_value.document.return_value.get.return_value = mock_cliente_doc

    with pytest.raises(HTTPException) as exc:
        service.delete_cliente_cascada("cli-missing", "comp-test")

    assert exc.value.status_code == 404


def test_delete_cliente_cascada_forbidden(service, mock_db):
    mock_cliente_doc = MagicMock(exists=True)
    mock_cliente_doc.to_dict.return_value = {"companyId": "other-company"}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_cliente_doc

    with pytest.raises(HTTPException) as exc:
        service.delete_cliente_cascada("cli-foreign", "comp-test")

    assert exc.value.status_code == 403


def test_delete_cliente_cascada_bloquea_pedidos_activos(service, mock_db, mock_pedidos_crud):
    mock_cliente_doc = MagicMock(exists=True)
    mock_cliente_doc.to_dict.return_value = {"companyId": "comp-test"}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_cliente_doc

    pedido_activo = MagicMock()
    pedido_activo.get.return_value = EstadoPedido.EN_PROGRESO
    mock_pedidos_crud.get_todos_los_pedidos.return_value = [pedido_activo]

    with pytest.raises(HTTPException) as exc:
        service.delete_cliente_cascada("cli-1", "comp-test")

    assert exc.value.status_code == 400
    assert "pedidos activos" in exc.value.detail


def test_delete_cliente_cascada_elimina_pedidos_cargas_y_cliente(service, mock_db, mock_pedidos_crud, mock_cargas_crud):
    mock_cliente_ref = MagicMock(name="cliente_ref")
    mock_cliente_doc = MagicMock(exists=True)
    mock_cliente_doc.to_dict.return_value = {"companyId": "comp-test"}
    mock_cliente_ref.get.return_value = mock_cliente_doc
    mock_db.collection.return_value.document.return_value = mock_cliente_ref

    pedido_completado = MagicMock()
    pedido_completado.id = "ped-1"
    pedido_completado.get.return_value = EstadoPedido.COMPLETADO
    pedido_completado.reference = MagicMock(name="pedido_ref")
    mock_pedidos_crud.get_todos_los_pedidos.return_value = [pedido_completado]

    carga_ref = MagicMock(name="carga_ref")
    mock_carga = MagicMock()
    mock_carga.reference = carga_ref
    mock_cargas_crud.get_todas_las_cargas.return_value = [mock_carga]

    batch = mock_db.batch.return_value

    service.delete_cliente_cascada("cli-1", "comp-test")

    batch.delete.assert_any_call(carga_ref)
    batch.delete.assert_any_call(pedido_completado.reference)
    batch.delete.assert_any_call(mock_cliente_ref)
    batch.commit.assert_called_once()
