import pytest
import datetime
from unittest.mock import MagicMock
from fastapi import HTTPException
from app.services.pedidos_service import PedidosService
from app.schemas.pedido import EstadoPedido

@pytest.fixture
def mock_pedidos_crud():
    return MagicMock(name="PedidosCRUD")

@pytest.fixture
def mock_cargas_crud():
    return MagicMock(name="CargasCRUD")

@pytest.fixture
def mock_cargas_service():
    return MagicMock(name="CargasService")

@pytest.fixture
def service(mock_pedidos_crud, mock_cargas_crud, mock_cargas_service):
    return PedidosService(
        crud=mock_pedidos_crud,
        cargas_crud=mock_cargas_crud,
        cargas_service=mock_cargas_service
    )

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

def test_pedidos_service_create_pedido(service, mock_pedidos_crud, mock_cargas_crud, valid_pedido_dict):
    # Arrange
    from app.schemas.pedido import CreatePedidoSchema, AsignacionCargaSchema

    valid_pedido_dict["cargas"] = [AsignacionCargaSchema(tipoCargaId="t1")]
    pedido = CreatePedidoSchema(**valid_pedido_dict)

    mock_pedidos_crud.create_pedido_doc.return_value = "new_p_id"

    # Mock tipo de carga
    mock_tipo_doc = MagicMock(exists=True)
    mock_tipo_doc.id = "t1"
    mock_tipo_doc.to_dict.return_value = {
        "nombre": "Tipo 1",
        "origen": "Madrid",
        "destino": "Barcelona",
        "mercancia": "Palets",
        "numBultos": 10,
        "peso": 500.0,
        "precio": 100.0,
        "pesoMax": 1000.0,
        "companyId": "comp1",
        "clienteId": "cli1"
    }
    mock_cargas_crud.get_tipo_carga_by_id.return_value = mock_tipo_doc
    mock_cargas_crud.create_carga_doc.return_value = "new_c_id"

    # Act
    service.create_pedido(pedido, "comp1")

    # Assert
    assert pedido.id == "new_p_id"
    assert pedido.companyId == "comp1"
    mock_pedidos_crud.create_pedido_doc.assert_called_once()
    mock_cargas_crud.get_tipo_carga_by_id.assert_called_once_with("t1")
    mock_cargas_crud.create_carga_doc.assert_called_once()

def test_pedidos_service_create_pedido_datos_completos(service, mock_pedidos_crud, mock_cargas_crud, valid_pedido_dict):
    # Arrange
    from app.schemas.pedido import CreatePedidoSchema, AsignacionCargaSchema

    valid_pedido_dict["cargas"] = [AsignacionCargaSchema(tipoCargaId="t1")]
    pedido = CreatePedidoSchema(**valid_pedido_dict)

    mock_pedidos_crud.create_pedido_doc.return_value = "new_p_id"

    # Mock para el tipo de carga con dimensiones y otros datos
    mock_tipo_doc = MagicMock(exists=True)
    mock_tipo_doc.id = "t1"
    mock_tipo_doc.to_dict.return_value = {
        "nombre": "Tipo Completo",
        "origen": "Madrid",
        "destino": "Barcelona",
        "mercancia": "Electrónica",
        "numBultos": 5,
        "peso": 200.0,
        "precio": 150.0,
        "largo": 1.2,
        "ancho": 0.8,
        "alto": 1.0,
        "pesoMax": 1000.0,
        "companyId": "comp1",
        "clienteId": "cli1"
    }
    mock_cargas_crud.get_tipo_carga_by_id.return_value = mock_tipo_doc

    carga_guardada = {}
    def mock_create_carga(data):
        nonlocal carga_guardada
        carga_guardada = data
        return "new_c_id"

    mock_cargas_crud.create_carga_doc.side_effect = mock_create_carga

    # Act
    service.create_pedido(pedido, "comp1")

    # Assert
    # Verificar que los campos críticos que antes fallaban están presentes
    assert carga_guardada["clienteId"] == "cli1"
    assert carga_guardada["companyId"] == "comp1"
    assert carga_guardada["largo"] == pytest.approx(1.2)
    assert carga_guardada["ancho"] == pytest.approx(0.8)
    assert carga_guardada["alto"] == pytest.approx(1.0)
    assert carga_guardada["pedidoId"] == "new_p_id"

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
