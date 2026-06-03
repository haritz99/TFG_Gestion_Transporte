import datetime
from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.dependencies.auth import get_current_encargado
from app.services import carta_porte_service as carta_porte_service_module
from app.services.carta_porte_service import CartaPorteService


@pytest.fixture
def service():
    return CartaPorteService(crud=MagicMock())


@pytest.fixture
def sample_carga_doc():
    ahora = datetime.datetime(2026, 5, 29, 8, 24, 18, tzinfo=datetime.timezone.utc)
    doc = MagicMock(exists=True, id="CRG-039")
    doc.to_dict.return_value = {
        "companyId": "empresa_test",
        "clienteNombre": "Cargas Rapidas S.L. 4",
        "clienteNif": "B77350878",
        "clienteDireccion": "Calle Falsa 5, 28074 Valencia (Barcelona)",
        "clienteTelefono": "600993064",
        "fechaCarga": ahora,
        "fechaDescarga": ahora + datetime.timedelta(days=7),
        "cartaPorteSnapshot": {
            "clienteDireccion": "Calle Falsa 5, 28074 Valencia (Barcelona)",
            "subcontratadoNombre": "Haritz Sub",
            "subcontratadoNumAutorizacion": "1234567AB",
        },
    }
    return doc


@pytest.fixture
def client_with_overrides():
    mock_service = MagicMock()
    app.dependency_overrides[get_current_encargado] = lambda: {
        "uid": "encargado_test",
        "companyId": "empresa_test",
        "rol": ["encargado"],
    }
    app.dependency_overrides[CartaPorteService] = lambda: mock_service
    with TestClient(app) as client:
        yield client, mock_service
    app.dependency_overrides.clear()


def test_get_carta_porte_template_data_normaliza_claves_y_fechas(service, sample_carga_doc):
    # Arrange
    service._crud.get_carga_doc.return_value = sample_carga_doc

    # Act
    carga = service.get_carta_porte_template_data("CRG-039", "empresa_test")

    # Assert
    assert carga["id"] == "CRG-039"
    assert carga["cliente_nombre"] == "Cargas Rapidas S.L. 4"
    assert carga["fecha_carga"] == "29/05/2026 08:24"
    assert carga["fecha_descarga"] == "05/06/2026 08:24"
    assert carga["carta_porte_snapshot"]["cliente_direccion"] == "Calle Falsa 5, 28074 Valencia (Barcelona)"
    assert carga["carta_porte_snapshot"]["subcontratado_num_autorizacion"] == "1234567AB"


def test_generar_carta_porte_pdf(service, sample_carga_doc, monkeypatch):
    # Arrange
    service._crud.get_carga_doc.return_value = sample_carga_doc

    class FakeHTML:
        def __init__(self, string, base_url=None):
            self.string = string
            self.base_url = base_url

        def write_pdf(self):
            assert "CRG-039" in self.string
            return b"%PDF-FAKE"

    monkeypatch.setattr(carta_porte_service_module, "HTML", FakeHTML)
    monkeypatch.setattr(
        carta_porte_service_module.CartaPorteService,
        "subir_pdf",
        lambda *args, **kwargs: "cartas_porte/empresa_test/carta_CRG-039.pdf",
    )
    monkeypatch.setattr(
        carta_porte_service_module.CartaPorteService,
        "generar_url_firmada",
        lambda *args, **kwargs: "https://fake.storage/signed/carta_CRG-039.pdf",
    )

    # Act
    url = service.generar_carta_porte_pdf("CRG-039", "empresa_test")

    # Assert
    assert isinstance(url, str)
    from urllib.parse import urlparse
    parsed = urlparse(url)
    assert parsed.scheme in ('http', 'https') or url.startswith('/')
    assert url.lower().endswith('.pdf') or 'carta' in url.lower()


def test_get_carta_porte_pdf_endpoint_returns_pdf(client_with_overrides):
    # Arrange
    client, mock_service = client_with_overrides
    mock_service.generar_carta_porte_pdf.return_value = "https://fake.storage/signed/carta_CRG-039.pdf"

    # Act
    response = client.get("/cargas/CRG-039/carta-porte")

    # Assert: endpoint returns JSON with the url
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    data = response.json()
    assert 'url' in data
    assert isinstance(data['url'], str)
    from urllib.parse import urlparse
    parsed = urlparse(data['url'])
    assert parsed.scheme in ('http', 'https') or data['url'].startswith('/')
    mock_service.generar_carta_porte_pdf.assert_called_once_with("CRG-039", "empresa_test")


def test_get_carta_porte_pdf_api_prefix_returns_pdf(client_with_overrides):
    # Arrange
    client, mock_service = client_with_overrides
    mock_service.generar_carta_porte_pdf.return_value = "https://fake.storage/signed/carta_CRG-039.pdf"

    # Act
    response = client.get("/cargas/CRG-039/carta-porte")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    data = response.json()
    assert 'url' in data
    assert isinstance(data['url'], str)
    from urllib.parse import urlparse
    parsed = urlparse(data['url'])
    assert parsed.scheme in ('http', 'https') or data['url'].startswith('/')
    mock_service.generar_carta_porte_pdf.assert_called_once_with("CRG-039", "empresa_test")



