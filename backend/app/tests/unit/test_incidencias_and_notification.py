import datetime
from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.dependencies.auth import get_current_conductor, get_current_encargado
from app.services.incidencias_service import IncidenciaService
from app.services.notification_service import NotificacionService
from app.services import carta_porte_service as carta_porte_service_module
from app.services.carta_porte_service import CartaPorteService


@pytest.fixture
def mock_user_crud():
    return MagicMock(name="UserCRUD")


@pytest.fixture
def notificacion_service(mock_user_crud):
    return NotificacionService(user_crud=mock_user_crud)


@pytest.fixture
def client_with_auth_overrides():
    app.dependency_overrides[get_current_conductor] = lambda: {
        "uid": "conductor_test",
        "companyId": "empresa_test",
        "rol": ["transportista"],
    }
    app.dependency_overrides[get_current_encargado] = lambda: {
        "uid": "encargado_test",
        "companyId": "empresa_test",
        "rol": ["encargado"],
    }
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


# Test 12: test_incidencias_endpoint_nested_create_respuesta_esperada
def test_incidencias_endpoint_nested_create_respuesta_esperada(client_with_auth_overrides):
    # Corresponde al test 12 de la lista backend.
    # Arrange
    client = client_with_auth_overrides
    mock_service = MagicMock()
    mock_service.create_incidencia.return_value = {"message": "Incidencia creada correctamente"}
    app.dependency_overrides[IncidenciaService] = lambda: mock_service
    payload = {"tipo": "averia", "descripcion": "Se rompió una pieza"}

    # Act
    response = client.post("/cargas/CRG-001/incidencia", json=payload)

    # Assert
    assert response.status_code == 200
    assert response.json() == {"message": "Incidencia creada correctamente"}
    mock_service.create_incidencia.assert_called_once()


# Test 13: test_incidencias_endpoint_nested_resolver_respuesta_esperada
def test_incidencias_endpoint_nested_resolver_respuesta_esperada(client_with_auth_overrides):
    # Corresponde al test 13 de la lista backend.
    # Arrange
    client = client_with_auth_overrides
    mock_service = MagicMock()
    mock_service.resolver_incidencia.return_value = {"message": "Incidencia resuelta"}
    app.dependency_overrides[IncidenciaService] = lambda: mock_service

    # Act
    response = client.patch("/cargas/CRG-001/incidencia/INC-001/resolver")

    # Assert
    assert response.status_code == 200
    assert response.json() == {"message": "Incidencia resuelta"}
    mock_service.resolver_incidencia.assert_called_once_with("INC-001")


# Test 14: test_fcm_evento_carga_asignada_payload_y_destinatario
def test_fcm_evento_carga_asignada_payload_y_destinatario(notificacion_service, mock_user_crud, monkeypatch):
    # Corresponde al test 14 de la lista backend.
    # Arrange
    mock_user_crud.get_by_id.return_value = MagicMock(exists=True)
    mock_user_crud.get_by_id.return_value.to_dict.return_value = {"fcmToken": "token_transportista"}

    captured = {}

    def fake_enviar(token, titulo, cuerpo, data=None):
        captured["token"] = token
        captured["titulo"] = titulo
        captured["cuerpo"] = cuerpo
        captured["data"] = data

    monkeypatch.setattr(notificacion_service, "enviar", fake_enviar)

    # Act
    notificacion_service.notificar(
        user_id="u123",
        roles=["transportista"],
        titulo="Carga asignada",
        cuerpo="Se te ha asignado una nueva carga",
        data={"evento": "carga_asignada", "cargaId": "c1", "pedidoId": "p1"},
    )

    # Assert
    assert captured["token"] == "token_transportista"
    assert captured["titulo"] == "Carga asignada"
    assert captured["data"]["evento"] == "carga_asignada"
    assert captured["data"]["cargaId"] == "c1"
    assert captured["data"]["pedidoId"] == "p1"


# Test 15: test_fcm_evento_carga_cedida_payload_y_destinatario
def test_fcm_evento_carga_cedida_payload_y_destinatario(notificacion_service, mock_user_crud, monkeypatch):
    # Corresponde al test 15 de la lista backend.
    # Arrange
    mock_user_crud.get_subcontratado_by_id.return_value = MagicMock(exists=True)
    mock_user_crud.get_subcontratado_by_id.return_value.to_dict.return_value = {"fcmToken": "token_subcontratado"}

    captured = {}

    def fake_enviar(token, titulo, cuerpo, data=None):
        captured["token"] = token
        captured["titulo"] = titulo
        captured["cuerpo"] = cuerpo
        captured["data"] = data

    monkeypatch.setattr(notificacion_service, "enviar", fake_enviar)

    # Act
    notificacion_service.notificar(
        user_id="sub1",
        roles=["subcontratado"],
        titulo="Carga cedida",
        cuerpo="Se te ha cedido una nueva carga",
        data={"evento": "carga_cedida", "cargaId": "c1", "subcontratadoId": "sub1"},
    )

    # Assert
    assert captured["token"] == "token_subcontratado"
    assert captured["titulo"] == "Carga cedida"
    assert captured["data"]["evento"] == "carga_cedida"
    assert captured["data"]["subcontratadoId"] == "sub1"


# Test 16: test_fcm_evento_carta_porte_generada_payload_y_destinatario
def test_fcm_evento_carta_porte_generada_payload_y_destinatario(monkeypatch):
    # Corresponde al test 16 de la lista backend.
    # Arrange
    mock_notificacion_service = MagicMock()
    mock_notificacion_service.notificar = MagicMock()
    mock_cargas_crud = MagicMock()
    mock_company_crud = MagicMock()
    mock_company_doc = MagicMock(exists=True)
    mock_company_doc.to_dict.return_value = {
        "nombre": "Empresa Test",
        "direccion": {
            "calle": "Calle Empresa",
            "ciudad": "Madrid",
            "provincia": "Madrid",
            "codigoPostal": "28001",
            "pais": "España",
        },
    }
    mock_company_crud.get_by_id.return_value = mock_company_doc
    mock_vehiculos_crud = MagicMock()
    service = CartaPorteService(
        notificacion_service=mock_notificacion_service,
        crud=mock_cargas_crud,
        company_crud=mock_company_crud,
        vehiculos_crud=mock_vehiculos_crud,
    )

    carga_doc = MagicMock(exists=True, id="CRG-001")
    carga_doc.to_dict.return_value = {"companyId": "empresa_test", "clienteId": "cli1", "subcontratadoId": "sub1", "clienteNombre": "Cliente Test", "clienteNif": "B12345678", "clienteDireccion": "Calle Cliente 1", "fechaCarga": datetime.datetime.now(datetime.timezone.utc), "fechaDescarga": datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=1)}
    carga_doc.reference = MagicMock()
    mock_cargas_crud.get_by_id.return_value = carga_doc
    monkeypatch.setattr(service, "generar_url_firmada", MagicMock(return_value="https://fake/carta.pdf"))
    monkeypatch.setattr(service, "subir_pdf", MagicMock(return_value="cartas_porte/empresa_test/carta_CRG-001.pdf"))
    monkeypatch.setattr(service, "_generar_qr_base64", MagicMock(return_value="qrdata"))

    fake_env = MagicMock()
    fake_template = MagicMock()
    fake_template.render.return_value = "<html></html>"
    fake_env.get_template.return_value = fake_template
    monkeypatch.setattr(carta_porte_service_module, "Environment", MagicMock(return_value=fake_env))
    monkeypatch.setattr(carta_porte_service_module, "FileSystemLoader", MagicMock())
    monkeypatch.setattr(carta_porte_service_module, "select_autoescape", MagicMock(return_value=None))
    monkeypatch.setattr(carta_porte_service_module, "HTML", MagicMock(return_value=MagicMock(write_pdf=MagicMock(return_value=b"%PDF"))))

    # Act
    service.generar_carta_porte_pdf("CRG-001", "empresa_test")

    # Assert
    calls = mock_notificacion_service.notificar.call_args_list
    assert len(calls) == 2
    assert calls[0].kwargs["user_id"] == "cli1"
    assert calls[0].kwargs["roles"] == ["cliente"]
    assert calls[0].kwargs["data"]["cargaId"] == "CRG-001"
    assert calls[1].kwargs["user_id"] == "sub1"
    assert calls[1].kwargs["roles"] == ["subcontratado"]
    assert calls[1].kwargs["data"]["cargaId"] == "CRG-001"


