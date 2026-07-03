import os
import pytest
import datetime
from unittest.mock import MagicMock
from fastapi.testclient import TestClient

os.environ.setdefault("FIRESTORE_EMULATOR_HOST", "localhost:8080")
os.environ.setdefault("GCLOUD_PROJECT", "test-project")
from google.cloud import firestore

from app.main import app


@pytest.fixture(scope="session")
def firestore_client():
    assert os.environ.get("FIRESTORE_EMULATOR_HOST"), (
        "FIRESTORE_EMULATOR_HOST no está definido."
    )
    client = firestore.Client(project=os.environ["GCLOUD_PROJECT"])
    yield client
    client.close()

@pytest.fixture(scope="session")
def client():
    with TestClient(app) as c:
        yield c

@pytest.fixture
def auth_headers():
    return {"Authorization": "Bearer test-token-valid"}

@pytest.fixture
def auth_headers_company_a():
    return {"Authorization": "Bearer company-a-token"}

@pytest.fixture
def auth_headers_company_b():
    return {"Authorization": "Bearer company-b-token"}

@pytest.fixture
def current_user_mock():
    return {
        "uid": "test_encargado_uid",
        "email": "encargado@empresa.com",
        "companyId": "empresa_test",
        "rol": ["encargado"]
    }

@pytest.fixture
def ubicacion_madrid():
    return {
        "direccion": {
            "calle": "Calle Falsa 123",
            "ciudad": "Madrid",
            "provincia": "Madrid",
            "codigoPostal": "28000",
            "pais": "España",
        },
        "lat": 40.4168,
        "lng": -3.7038,
    }

@pytest.fixture
def ubicacion_barcelona():
    return {
        "direccion": {
            "calle": "Calle Real 1",
            "ciudad": "Barcelona",
            "provincia": "Barcelona",
            "codigoPostal": "08001",
            "pais": "España",
        },
        "lat": 41.3874,
        "lng": 2.1686,
    }

@pytest.fixture
def tipo_carga_doc_dict(ubicacion_madrid, ubicacion_barcelona):
    return {
        "nombre": "Tipo 1",
        "origen": ubicacion_madrid,
        "destino": ubicacion_barcelona,
        "mercancia": "Palets",
        "numBultos": 10,
        "peso": 500.0,
        "precio": 100.0,
        "largo": 1.2,
        "ancho": 0.8,
        "alto": 1.0,
        "pesoMax": 1000.0,
        "companyId": "comp1",
        "clienteId": "cli1",
    }

@pytest.fixture
def cliente_doc_dict():
    return {
        "nombreComercial": "Mi Cliente",
        "email": "cli@test.com",
        "nif": "B12345678",
        "telefono": "600123456",
        "personaContacto": "Juan",
        "companyId": "comp1",
        "direccionFiscal": {
            "calle": "Calle Falsa 123",
            "ciudad": "Madrid",
            "provincia": "Madrid",
            "codigoPostal": "28000",
            "pais": "España",
        },
    }

@pytest.fixture
def subcontratado_doc_dict():
    return {
        "companyId": "comp1",
        "email": "sub@test.com",
        "nombreComercial": "Sub S.L.",
        "nif": "B12345678",
        "telefono": "600123456",
        "numeroAutorizacion": "ABC123",
        "direccionFiscal": {
            "calle": "Calle Sub 1",
            "ciudad": "Madrid",
            "provincia": "Madrid",
            "codigoPostal": "28000",
            "pais": "España",
        },
    }

@pytest.fixture
def build_firestore_doc():
    def _build(*, exists=True, doc_id="doc-1", data=None):
        doc = MagicMock(exists=exists)
        doc.id = doc_id
        doc.to_dict.return_value = data or {}
        return doc

    return _build
@pytest.fixture
def pedido_doc_dict(valid_carga_dict):
    return {
        "descripcion": "Pedido test",
        "fechaCarga": datetime.datetime.now(datetime.timezone.utc),
        "fechaDescarga": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1),
        "cargas": [valid_carga_dict],
        "origenes": ["Madrid"],
        "destinos": ["Barcelona"],
        "estado": "planificado",
        "clienteId": "cli1",
        "companyId": "comp1",
    }

@pytest.fixture
def create_pedido_dict():
    return {
        "descripcion": "Pedido test",
        "fechaCarga": datetime.datetime.now(datetime.timezone.utc),
        "fechaDescarga": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1),
        "cargas": [{"tipoCargaId": "t1"}],
        "clienteId": "cli1",
        "companyId": "comp1",
    }

@pytest.fixture
def fake_pedido():
    """
    Pedido para tests de integracion (lo que envía el front)
    """
    ahora = datetime.datetime.now(datetime.timezone.utc)
    return {
        "destinatarioNombre": "Cliente Test SL",
        "destinatarioNif": "B12345678",
        "destinatarioDireccion": "Rambla Catalunya 5, Barcelona",
        "descripcion": "Pedido de test",
        "clienteId": "cli1",
        "fechaCarga": ahora.isoformat(),
        "fechaDescarga": (ahora + datetime.timedelta(hours=24)).isoformat(),
        "cargas": [
            {"tipoCargaId": "t1"},
        ],
    }

@pytest.fixture
def carga_doc_dict(ubicacion_madrid, ubicacion_barcelona):
    ahora = datetime.datetime.now(datetime.timezone.utc)
    return {
        "pedidoId": "p1",
        "origen": ubicacion_madrid,
        "destino": ubicacion_barcelona,
        "mercancia": "Palets",
        "numBultos": 10,
        "peso": 500.0,
        "precio": 100.0,
        "fechaCarga": ahora + datetime.timedelta(hours=1),
        "fechaDescarga": ahora + datetime.timedelta(hours=5),
        "estado": "pendiente",
        "companyId": "comp1",
    }

@pytest.fixture
def valid_carga_dict(carga_doc_dict):
    return carga_doc_dict

@pytest.fixture
def valid_pedido_dict(pedido_doc_dict):
    return pedido_doc_dict





