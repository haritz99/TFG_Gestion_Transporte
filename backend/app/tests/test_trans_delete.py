import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock
from app.main import app
from app.dependencies.auth import get_current_encargado
from app.services.trans_service import get_trans_service

@pytest.fixture
def client_with_mocks():
    mock_service = MagicMock()
    app.dependency_overrides[get_current_encargado] = lambda: {
        "uid": "encargado-test",
        "companyId": "comp-test",
        "rol": ["encargado"],
    }
    app.dependency_overrides[get_trans_service] = lambda: mock_service
    with TestClient(app) as c:
        yield c, mock_service
    app.dependency_overrides.clear()

def test_delete_transportista_not_found_returns_404(client_with_mocks):
    client, mock_service = client_with_mocks
    from fastapi import HTTPException
    mock_service.delete_trans.side_effect = HTTPException(status_code=404, detail="Transportista no encontrado")
    response = client.delete("/trans/missing")
    assert response.status_code == 404
    assert response.json()["detail"] == "Transportista no encontrado"

def test_delete_user_without_transportista_role_returns_400(client_with_mocks):
    client, mock_service = client_with_mocks
    from fastapi import HTTPException
    mock_service.delete_trans.side_effect = HTTPException(status_code=400, detail="El usuario indicado no es transportista")
    response = client.delete("/trans/u1")
    assert response.status_code == 400
    assert response.json()["detail"] == "El usuario indicado no es transportista"

def test_delete_transportista_with_vehicle_returns_vehicle_released_message(client_with_mocks):
    client, mock_service = client_with_mocks
    mock_service.delete_trans.return_value = {"message": "Transportista eliminado con éxito y vehículo liberado"}
    response = client.delete("/trans/u2")
    assert response.status_code == 200
    assert response.json()["message"] == "Transportista eliminado con éxito y vehículo liberado"

def test_delete_transportista_without_vehicle_returns_success_message(client_with_mocks):
    client, mock_service = client_with_mocks
    mock_service.delete_trans.return_value = {"message": "Transportista eliminado con éxito"}
    response = client.delete("/trans/u3")
    assert response.status_code == 200
    assert response.json()["message"] == "Transportista eliminado con éxito"


