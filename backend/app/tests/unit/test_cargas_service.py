import pytest
import datetime
from unittest.mock import MagicMock
from app.services.cargas_service import CargasService
from app.schemas.carga import EstadoCarga

@pytest.fixture
def mock_cargas_crud():
    return MagicMock(name="CargasCRUD")


@pytest.fixture
def mock_users_crud():
    return MagicMock(name="UserCRUD")


@pytest.fixture
def mock_notificacion_service():
    return MagicMock(name="NotificacionService")


@pytest.fixture
def service(mock_cargas_crud, mock_users_crud, mock_notificacion_service):
    return CargasService(
        crud=mock_cargas_crud,
        users_crud=mock_users_crud,
        notificacion_service=mock_notificacion_service,
    )

@pytest.fixture
def valid_carga_dict():
    ahora = datetime.datetime.now(datetime.timezone.utc)
    return {
        "pedidoId": "p1",
        "origen": {"ciudad": "Madrid"} ,
        "destino": {"ciudad": "Barcelona"},
        "mercancia": "Palets",
        "numBultos": 10,
        "peso": 500.0,
        "precio": 100.0,
        "fechaCarga": ahora,
        "fechaDescarga": ahora + datetime.timedelta(hours=5),
        "estado": EstadoCarga.PENDIENTE,
        "companyId": "comp1"
    }

def test_cargas_service_fetch_cargas_filtros(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "c1"
    mock_doc.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_todas_las_cargas.return_value = [mock_doc]

    # Act
    res = service.fetch_cargas("comp1", estado=EstadoCarga.PENDIENTE)

    # Assert
    assert len(res) == 1
    assert res[0].id == "c1"

def test_cargas_service_calculate_cargas_hoy(service, mock_cargas_crud):
    # Arrange
    mock_v = MagicMock()
    mock_v.value = 5
    mock_cargas_crud.get_cargas_hoy_count.return_value = [[mock_v]]
    sod = datetime.datetime(2024, 1, 1, 0, 0, 0, tzinfo=datetime.timezone.utc)
    eod = datetime.datetime(2024, 1, 1, 23, 59, 59, tzinfo=datetime.timezone.utc)

    # Act
    res = service.calculate_cargas_hoy("comp1", sod, eod)

    # Assert
    assert res == 5

def test_cargas_service_get_carga_by_id_existe(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock(exists=True, id="c1")
    mock_doc.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc

    # Act
    res = service.get_carga_by_id("c1", "comp1")

    # Assert
    assert res.id == "c1"


def test_cargas_service_delete_carga_ok(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock(exists=True)
    mock_doc.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc

    # Act
    service.delete_carga("c1", "comp1")

    # Assert
    mock_cargas_crud.delete_carga_doc.assert_called_once_with("c1")


def test_cargas_service_ceder_carga_subcontratado_notifica(service, mock_cargas_crud, mock_users_crud, mock_notificacion_service, valid_carga_dict):
    mock_doc_carga = MagicMock(exists=True)
    mock_doc_carga.id = "c1"
    mock_doc_carga.reference = MagicMock(name="carga_ref")
    mock_doc_carga.to_dict.return_value = {
        **valid_carga_dict,
        "cartaPorteSnapshot": {
            "clienteNombre": "Mi Cliente",
            "clienteNif": "B12345678",
            "clienteDireccion": "Calle Falsa 123, 28000 Madrid (Madrid)",
        },
        "precio": 100.0,
    }
    mock_cargas_crud.get_carga_doc.return_value = mock_doc_carga

    mock_sub_doc = MagicMock(exists=True)
    mock_sub_doc.id = "sub1"
    mock_sub_doc.to_dict.return_value = {
        "companyId": "comp1",
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
    mock_users_crud.get_subcontratado_by_id.return_value = mock_sub_doc

    batch = mock_cargas_crud.get_batch.return_value

    result = service.ceder_carga_subcontratado("c1", "sub1", "comp1")

    assert result.estado == EstadoCarga.CEDIDO
    call_kwargs = mock_notificacion_service.notificar.call_args.kwargs
    assert call_kwargs["user_id"] == "sub1"
    assert call_kwargs["roles"] == ["subcontratado"]
    assert call_kwargs["titulo"] == "Carga cedida"
    assert call_kwargs["data"]["evento"] == "carga_cedida"
    assert call_kwargs["data"]["cargaId"] == "c1"
    assert call_kwargs["data"]["subcontratadoId"] == "sub1"
    batch.commit.assert_called_once()

def test_cargas_service_calculate_asignados(service, mock_cargas_crud):
    # Arrange
    mock_res = MagicMock()
    mock_res.value = 12
    # Simulando el formato de retorno de agregación de Firestore [[CountRecord]]
    mock_cargas_crud.get_cargas_count.return_value = [[mock_res]]

    # Act
    res = service.calculate_asignados("comp1")

    # Assert
    assert res == 12
    mock_cargas_crud.get_cargas_count.assert_called_once_with("comp1", "asignado")

def test_cargas_service_calculate_sin_asignar(service, mock_cargas_crud):
    # Arrange
    mock_res = MagicMock()
    mock_res.value = 8
    mock_cargas_crud.get_cargas_count.return_value = [[mock_res]]

    # Act
    res = service.calculate_sin_asignar("comp1")

    # Assert
    assert res == 8
    mock_cargas_crud.get_cargas_count.assert_called_once_with("comp1", "pendiente")

