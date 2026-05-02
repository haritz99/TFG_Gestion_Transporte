import pytest
from fastapi.testclient import TestClient

from app.main import app

@pytest.fixture(scope="session")
def client():
    with TestClient(app) as c:
        yield c

@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer test-token-valid"}

@pytest.fixture
def current_user_mock():
    return {
        "uid": "test_encargado_uid",
        "email": "encargado@empresa.com",
        "companyId": "empresa_test",
        "rol": ["encargado"]
    }

