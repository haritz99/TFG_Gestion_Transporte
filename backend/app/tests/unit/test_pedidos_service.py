import pytest
import datetime
from unittest.mock import MagicMock
from fastapi import HTTPException
from app.services.pedidos_service import PedidosService
from app.schemas.pedido import PedidoSchema, EstadoPedido

@pytest.fixture
def mock_pedidos_crud():
    return MagicMock(name="PedidosCRUD")

@pytest.fixture
def mock_cargas_service():
    return MagicMock(name="CargasService")

@pytest.fixture
def service(mock_pedidos_crud, mock_cargas_service):
    return PedidosService(crud=mock_pedidos_crud, cargas_service=mock_cargas_service)

@pytest.fixture
def valid_pedido_dict():
    ahora = datetime.datetime.now(datetime.timezone.utc)
    return {
        "descripcion": "Test Pedido",
        "fechaCarga": ahora,
        "fechaDescarga": ahora + datetime.timedelta(days=1),
        "origenes": ["Madrid"],
        "destinos": ["Barcelona"],
        "estado": EstadoPedido.PLANIFICADO,
        "clienteId": "cli1",
        "companyId": "comp1"
    }

def test_pedidos_service_fetch_pedidos_filtros(service, mock_pedidos_crud, valid_pedido_dict):
    # Arrange
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "p1"
    mock_doc.to_dict.return_value = valid_pedido_dict
    mock_pedidos_crud.get_todos_los_pedidos.return_value = [mock_doc]
    fecha = datetime.date(2024, 1, 1)

    # Act
    res = service.fetch_pedidos("comp1", cliente_id="c1", estado="planificado", fecha_inicio=fecha)

    # Assert
    assert len(res) == 1
    assert res[0].id == "p1"
    mock_pedidos_crud.get_todos_los_pedidos.assert_called_once()

def test_pedidos_service_get_pedido_by_id_existe(service, mock_pedidos_crud, valid_pedido_dict):
    # Arrange
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "p1"
    mock_doc.to_dict.return_value = valid_pedido_dict
    mock_pedidos_crud.get_pedido_doc.return_value = mock_doc

    # Act
    res = service.get_pedido_by_id("p1", "comp1")

    # Assert
    assert res.id == "p1"
    mock_pedidos_crud.get_pedido_doc.assert_called_once_with("p1")

def test_pedidos_service_get_pedido_by_id_no_existe(service, mock_pedidos_crud):
    # Arrange
    mock_doc = MagicMock(exists=False)
    mock_pedidos_crud.get_pedido_doc.return_value = mock_doc

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.get_pedido_by_id("p_inv", "comp1")
    assert exc.value.status_code == 404

def test_pedidos_service_create_pedido(service, mock_pedidos_crud, valid_pedido_dict):
    # Arrange
    pedido = PedidoSchema(**valid_pedido_dict)
    mock_pedidos_crud.create_pedido_doc.return_value = "new_p_id"

    # Act
    res = service.create_pedido(pedido, "comp1")

    # Assert
    assert res.id == "new_p_id"
    assert res.companyId == "comp1"
    mock_pedidos_crud.create_pedido_doc.assert_called_once()

def test_pedidos_service_delete_pedido_ok(service, mock_pedidos_crud, mock_cargas_service, valid_pedido_dict):
    # Arrange
    mock_doc = MagicMock(exists=True)
    # Cambiamos estado a completado para que deje borrar
    valid_pedido_dict["estado"] = "completado"
    mock_doc.to_dict.return_value = valid_pedido_dict
    mock_pedidos_crud.get_pedido_doc.return_value = mock_doc

    mock_carga = MagicMock()
    mock_carga.id = "c1"
    mock_cargas_service.fetch_cargas.return_value = [mock_carga]

    # Act
    service.delete_pedido("p1", "comp1")

    # Assert
    mock_pedidos_crud.delete_pedido_y_cargas.assert_called_once()

def test_pedidos_service_delete_pedido_no_auth(service, mock_pedidos_crud, valid_pedido_dict):
    # Arrange
    mock_doc = MagicMock(exists=True)
    valid_pedido_dict["companyId"] = "otra"
    mock_doc.to_dict.return_value = valid_pedido_dict
    mock_pedidos_crud.get_pedido_doc.return_value = mock_doc

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.delete_pedido("p1", "comp1")
    assert exc.value.status_code == 403

def test_pedidos_service_delete_pedido_estado_invalido(service, mock_pedidos_crud, valid_pedido_dict):
    # Arrange
    mock_doc = MagicMock(exists=True)
    valid_pedido_dict["estado"] = "planificado"
    mock_doc.to_dict.return_value = valid_pedido_dict
    mock_pedidos_crud.get_pedido_doc.return_value = mock_doc

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.delete_pedido("p1", "comp1")
    assert exc.value.status_code == 400
