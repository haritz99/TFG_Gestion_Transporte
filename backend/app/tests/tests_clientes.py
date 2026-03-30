import pytest
from unittest.mock import MagicMock
from fastapi import FastAPI
from fastapi.testclient import TestClient

from backend.app.dependencies.auth import get_current_encargado
from backend.app.routers import clientes
from backend.app.schemas.pedido import EstadoPedido

def get_test_app():
    app = FastAPI()
    app.include_router(clientes.router)
    
    def override_get_current_encargado():
        return {
            "uid": "encargado123",
            "companyId": "comp-test",
            "rol": ["encargado"],
        }
        
    app.dependency_overrides[get_current_encargado] = override_get_current_encargado
    return app

client = TestClient(get_test_app())

@pytest.fixture
def mock_db(monkeypatch):
    mock = MagicMock()
    monkeypatch.setattr(clientes, "db", mock)
    return mock

def test_get_clientes(mock_db):
    mock_query = MagicMock()
    mock_db.collection.return_value.where.return_value.stream.return_value = [
        MagicMock(id="c1", to_dict=lambda: {"id": "c1", "nombreComercial": "Cli 1", "companyId": "comp-test"}),
        MagicMock(id="c2", to_dict=lambda: {"id": "c2", "nombreComercial": "Cli 2", "companyId": "comp-test"}),
    ]
    
    response = client.get("/clientes/")
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["nombreComercial"] == "Cli 1"
    mock_db.collection.assert_called_with("clientes")

def test_create_cliente(mock_db):
    mock_doc_ref = MagicMock()
    mock_doc_ref.id = "new_cli_id"
    mock_db.collection.return_value.document.return_value = mock_doc_ref
    
    payload = {"nombreComercial": "Cliente Nuevo", "pedidos": [], "companyId": "comp-test"}
    response = client.post("/clientes/", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert data["id"] == "new_cli_id"
    assert data["companyId"] == "comp-test"
    mock_db.collection.assert_called_with("clientes")
    mock_doc_ref.set.assert_called_once()
    
def test_delete_cliente_not_found(mock_db):
    mock_doc = MagicMock()
    mock_doc.exists = False
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc
    
    response = client.delete("/clientes/notfound")
    assert response.status_code == 404

def test_delete_cliente_forbidden(mock_db):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {"companyId": "other-company"}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc
    
    response = client.delete("/clientes/foreign")
    assert response.status_code == 403

def test_delete_cliente_with_active_pedidos(mock_db, monkeypatch):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {"companyId": "comp-test"}
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc
    
    # En vez de mockear la cadena inmensa de Firestore de forma frágil, 
    # mockeamos directamente la función fetch_pedidos pura que importa `clientes.py`
    mock_fetch = MagicMock(return_value=[{"id": "p1", "estado": EstadoPedido.EN_PROGRESO.value}])
    monkeypatch.setattr(clientes, "fetch_pedidos", mock_fetch)
    
    response = client.delete("/clientes/c1")
    assert response.status_code == 400
    assert "EN_PROGRESO" in response.json()["detail"]

def test_delete_cliente_success_cascade(mock_db, monkeypatch):
    # Cliente existe y es de la compañía
    mock_cliente_doc = MagicMock()
    mock_cliente_doc.exists = True
    mock_cliente_doc.to_dict.return_value = {"companyId": "comp-test"}
    
    # Doc.get() del cliente
    mock_cliente_ref = MagicMock()
    mock_cliente_ref.get.return_value = mock_cliente_doc
    
    # Mockear `fetch_pedidos` para que finja devolver un pedido completado 
    mock_fetch = MagicMock(return_value=[{"id": "p1", "estado": EstadoPedido.COMPLETADO.value}])
    monkeypatch.setattr(clientes, "fetch_pedidos", mock_fetch)

    # Configurar qué devuelve document() según su argumento
    # db.collection("clientes").document(...)
    def mock_document_side_effect(doc_id=None):
        return mock_cliente_ref
        
    mock_db.collection.return_value.document.side_effect = mock_document_side_effect
    
    def collection_side_effect(name):
        collection_mock = MagicMock()
        if name == "clientes":
            collection_mock.document.return_value = mock_cliente_ref
        elif name == "cargas":
            carga_mock = MagicMock()
            carga_mock.reference = MagicMock()
            
            where_1_mock = MagicMock()
            where_2_mock = MagicMock()
            where_2_mock.stream.return_value = [carga_mock]
            
            where_1_mock.where.return_value = where_2_mock
            collection_mock.where.return_value = where_1_mock
            
        elif name == "pedidos":
            # Para el borrado: db.collection("pedidos").document(pedido_id).delete()
            pedido_doc_ref = MagicMock()
            collection_mock.document.return_value = pedido_doc_ref
            
        return collection_mock
        
    mock_db.collection.side_effect = collection_side_effect
    
    response = client.delete("/clientes/c1")
    assert response.status_code == 204
    
    # Verificar que se llamó delete() del cliente
    mock_cliente_ref.delete.assert_called_once()
