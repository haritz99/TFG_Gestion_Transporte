import pytest
import datetime
from unittest.mock import MagicMock, ANY
from fastapi import HTTPException
from google.cloud.firestore import ArrayRemove
from app.services.cargas_service import CargasService
from app.schemas.carga import CargaSchema, EstadoCarga, CargaUpdateDetallesSchema

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
def mock_pedidos_crud():
    return MagicMock(name="PedidosCRUD")


@pytest.fixture
def mock_vehiculos_crud():
    return MagicMock(name="VehiculoCRUD")


@pytest.fixture
def mock_carta_porte_service():
    return MagicMock(name="CartaPorteService")


@pytest.fixture
def service(mock_cargas_crud, mock_users_crud, mock_notificacion_service, mock_pedidos_crud, mock_vehiculos_crud, mock_carta_porte_service):
    return CargasService(
        crud=mock_cargas_crud,
        pedidos_crud=mock_pedidos_crud,
        users_crud=mock_users_crud,
        vehiculos_crud=mock_vehiculos_crud,
        notificacion_service=mock_notificacion_service,
        carta_porte_service=mock_carta_porte_service,
    )

@pytest.fixture
def valid_carga_dict(carga_doc_dict):
    return {
        **carga_doc_dict,
        "estado": EstadoCarga.PENDIENTE,
    }


def _valid_pedido_doc(pedido_doc_dict):
    mock_pedido_doc = MagicMock(exists=True)
    mock_pedido_doc.id = "p1"
    mock_pedido_doc.to_dict.return_value = pedido_doc_dict
    return mock_pedido_doc


def _build_valid_carga(carga_doc_dict, **overrides):
    payload = {
        **carga_doc_dict,
        "id": overrides.pop("id", "c1"),
        "pedidoId": overrides.pop("pedidoId", "p1"),
    }
    payload.update(overrides)
    payload = {k: v for k, v in payload.items() if v is not None}
    return CargaSchema(**payload)

def test_cargas_service_fetch_cargas_filtros(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "c1"
    mock_doc.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_all.return_value = [mock_doc]

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
    mock_cargas_crud.get_by_id.return_value = mock_doc

    # Act
    res = service.get_carga_by_id("c1", "comp1")

    # Assert
    assert res.id == "c1"


def test_cargas_service_bulk_update_ok_persiste_cargas_en_lote(service, mock_cargas_crud, mock_pedidos_crud, pedido_doc_dict, carga_doc_dict):
    # Corresponde al test 1 de la lista backend.
    # Arrange
    mock_pedido_doc = _valid_pedido_doc(pedido_doc_dict)
    mock_pedido_doc.id = "p1"
    mock_pedidos_crud.get_pedido_ref.return_value = MagicMock(name="pedido_ref_p1")
    mock_pedidos_crud.get_pedidos_by_refs.return_value = [mock_pedido_doc]

    carga_1 = _build_valid_carga(carga_doc_dict, id="c1", pedidoId="p1")
    carga_2 = _build_valid_carga(carga_doc_dict, id="c2", pedidoId="p1", fechaCarga=carga_1.fechaCarga + datetime.timedelta(hours=1), fechaDescarga=carga_1.fechaDescarga + datetime.timedelta(hours=1))
    batch = MagicMock()
    mock_cargas_crud.get_batch.return_value = batch

    ref_1 = MagicMock(name="ref_1")
    ref_2 = MagicMock(name="ref_2")
    mock_cargas_crud.get_carga_ref.side_effect = [ref_1, ref_2]

    # Act
    result = service.bulk_update_cargas([carga_1, carga_2], "comp1")

    # Assert
    assert len(result) == 2
    assert result[0].companyId == "comp1"
    assert result[0].clienteId == "cli1"
    assert result[1].companyId == "comp1"
    assert result[1].clienteId == "cli1"
    assert batch.update.call_count == 2
    batch.commit.assert_called_once()


def test_cargas_service_bulk_update_rechaza_carga_sin_pedido(service, mock_cargas_crud, carga_doc_dict):
    # Corresponde al test 2 de la lista backend.
    # Arrange
    carga = _build_valid_carga(carga_doc_dict, id="c1", pedidoId=None)

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.bulk_update_cargas([carga], "comp1")

    assert exc.value.status_code == 400


def test_cargas_service_bulk_update_rechaza_pedido_inexistente(service, mock_cargas_crud, mock_pedidos_crud, carga_doc_dict):
    # Corresponde al test 3 de la lista backend.
    # Arrange
    carga = _build_valid_carga(carga_doc_dict, id="c1", pedidoId="p_inexistente")
    mock_pedido_doc = MagicMock(exists=False)
    mock_pedido_doc.id = "p_inexistente"
    mock_pedidos_crud.get_pedido_ref.return_value = MagicMock(name="pedido_ref_p_inexistente")
    mock_pedidos_crud.get_pedidos_by_refs.return_value = [mock_pedido_doc]

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.bulk_update_cargas([carga], "comp1")

    assert exc.value.status_code == 404


def test_cargas_service_bulk_update_rechaza_ref_invalida(service, mock_cargas_crud, mock_pedidos_crud, pedido_doc_dict, carga_doc_dict):
    # Corresponde al test 4 de la lista backend.
    # Arrange
    carga = _build_valid_carga(carga_doc_dict, id="c1", pedidoId="p1")
    mock_pedido_doc = _valid_pedido_doc(pedido_doc_dict)
    mock_pedido_doc.id = "p1"
    mock_pedidos_crud.get_pedido_ref.return_value = MagicMock(name="pedido_ref_p1")
    mock_pedidos_crud.get_pedidos_by_refs.return_value = [mock_pedido_doc]
    mock_cargas_crud.get_batch.return_value = MagicMock()
    mock_cargas_crud.get_carga_ref.return_value = None

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.bulk_update_cargas([carga], "comp1")

    assert exc.value.status_code == 500
    assert "referencia" in str(exc.value.detail).lower()

def test_cargas_service_ceder_carga_subcontratado_notifica(service, mock_cargas_crud, mock_users_crud, mock_notificacion_service, carga_doc_dict, subcontratado_doc_dict):
    mock_doc_carga = MagicMock(exists=True)
    mock_doc_carga.id = "c1"
    mock_doc_carga.reference = MagicMock(name="carga_ref")
    mock_doc_carga.to_dict.return_value = {
        **carga_doc_dict,
        "cartaPorteSnapshot": {
            "clienteNombre": "Mi Cliente",
            "clienteNif": "B12345678",
            "clienteDireccion": "Calle Falsa 123, 28000 Madrid (Madrid)",
        },
        "precio": 100.0,
    }
    mock_cargas_crud.get_by_id.return_value = mock_doc_carga

    mock_sub_doc = MagicMock(exists=True)
    mock_sub_doc.id = "sub1"
    mock_sub_doc.to_dict.return_value = subcontratado_doc_dict
    mock_users_crud.get_subcontratado_by_id.return_value = mock_sub_doc

    mock_updated_doc = MagicMock(exists=True)
    mock_updated_doc.id = "c1"
    mock_updated_doc.to_dict.return_value = {
        **carga_doc_dict,
        "estado": EstadoCarga.CEDIDO,
        "companyId": "comp1",
        "subcontratadoId": "sub1",
        "cartaPorteSnapshot": {
            "clienteNombre": "Mi Cliente",
            "clienteNif": "B12345678",
            "clienteDireccion": "Calle Falsa 123, 28000 Madrid (Madrid)",
            "subcontratadoNombre": "Sub S.L.",
        },
    }
    mock_cargas_crud.get_by_id.side_effect = [mock_doc_carga, mock_updated_doc]

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
    mock_cargas_crud.get_cargas_count.assert_called_once_with("comp1", "asignado", ANY, ANY)

def test_cargas_service_calculate_sin_asignar(service, mock_cargas_crud):
    # Arrange
    mock_res = MagicMock()
    mock_res.value = 8
    mock_cargas_crud.get_cargas_count.return_value = [[mock_res]]

    # Act
    res = service.calculate_sin_asignar("comp1")

    # Assert
    assert res == 8
    mock_cargas_crud.get_cargas_count.assert_called_once_with("comp1", "planificado", ANY, ANY)


def test_update_estado_descender_cedido_a_planificado_limpia_carga(service, mock_cargas_crud, mock_users_crud, mock_carta_porte_service, carga_doc_dict, subcontratado_doc_dict):
    # Arrange
    doc_inicial = MagicMock(exists=True)
    doc_inicial.id = "c1"
    doc_inicial.reference = MagicMock(name="carga_ref")
    doc_inicial.to_dict.return_value = {
        **carga_doc_dict,
        "estado": EstadoCarga.CEDIDO,
        "subcontratadoId": "sub1",
        "comisionCesion": 3.0,
        "transportistaId": "t1",
        "conductorNombre": "Juan Pérez",
        "vehiculoId": "V1",
        "subVehiculoMatricula": "1234ABC",
        "subRemolqueMatricula": "5678DEF",
        "cartaPorteSnapshot": {"clienteNombre": "Mi Cliente"},
        "carta_porte_url": "https://fake/signed/carta_CRG-039.pdf",
    }

    doc_final = MagicMock(exists=True)
    doc_final.id = "c1"
    doc_final.to_dict.return_value = {
        **carga_doc_dict,
        "estado": EstadoCarga.PLANIFICADO,
        "cartaPorteSnapshot": None,
        "carta_porte_url": None,
    }
    mock_cargas_crud.get_by_id.side_effect = [doc_inicial, doc_final]

    mock_sub_doc = MagicMock(exists=True)
    mock_sub_doc.id = "sub1"
    mock_sub_doc.reference = MagicMock(name="sub_ref")
    mock_sub_doc.to_dict.return_value = subcontratado_doc_dict
    mock_users_crud.get_subcontratado_by_id.return_value = mock_sub_doc

    batch = mock_cargas_crud.get_batch.return_value

    # Act
    result = service.update_estado_carga("c1", EstadoCarga.PLANIFICADO.value, "comp1")

    # Assert
    assert result.estado == EstadoCarga.PLANIFICADO

    calls = batch.update.call_args_list
    assert len(calls) == 2

    carga_payload = calls[0][0][1]
    assert carga_payload["estado"] == "planificado"
    assert carga_payload["cartaPorteSnapshot"] is None
    assert carga_payload["carta_porte_url"] is None
    assert carga_payload["subcontratadoId"] is None
    assert carga_payload["comisionCesion"] is None
    assert carga_payload["transportistaId"] is None
    assert carga_payload["conductorNombre"] is None
    assert carga_payload["vehiculoId"] is None

    sub_payload = calls[1][0][1]
    assert isinstance(sub_payload["cargasCedidas"], type(ArrayRemove(["x"])))
    assert calls[1][0][0] == mock_sub_doc.reference

    batch.commit.assert_called_once()
    mock_carta_porte_service.eliminar_carta_porte_pdf.assert_called_once_with("comp1", "c1")


def test_update_estado_transicion_normal_no_limpia(service, mock_cargas_crud, mock_carta_porte_service, carga_doc_dict):
    # Arrange
    doc_inicial = MagicMock(exists=True)
    doc_inicial.id = "c1"
    doc_inicial.to_dict.return_value = {
        **carga_doc_dict,
        "estado": EstadoCarga.ASIGNADO,
        "transportistaId": "t1",
        "vehiculoId": "V1",
    }

    doc_final = MagicMock(exists=True)
    doc_final.id = "c1"
    doc_final.to_dict.return_value = {
        **carga_doc_dict,
        "estado": EstadoCarga.EN_TRANSITO,
        "transportistaId": "t1",
        "vehiculoId": "V1",
    }
    mock_cargas_crud.get_by_id.side_effect = [doc_inicial, doc_final]

    # Act
    result = service.update_estado_carga("c1", EstadoCarga.EN_TRANSITO.value, "comp1")

    # Assert
    assert result.estado == EstadoCarga.EN_TRANSITO
    mock_cargas_crud.update.assert_called_once()
    mock_cargas_crud.get_batch.assert_not_called()
    mock_carta_porte_service.eliminar_carta_porte_pdf.assert_not_called()


def test_update_carga_detalles_modifica_y_persiste(service, mock_cargas_crud, carga_doc_dict):
    # Arrange
    doc_inicial = MagicMock(exists=True)
    doc_inicial.id = "c1"
    doc_inicial.to_dict.return_value = {**carga_doc_dict, "id": "c1", "companyId": "comp1"}

    doc_final = MagicMock(exists=True)
    doc_final.id = "c1"
    doc_final.to_dict.return_value = {
        **carga_doc_dict,
        "id": "c1",
        "companyId": "comp1",
        "peso": 800.0,
        "numBultos": 15,
    }
    mock_cargas_crud.get_by_id.side_effect = [doc_inicial, doc_final]

    cambios = CargaUpdateDetallesSchema(peso=800.0, numBultos=15)

    # Act
    result = service.update_carga_detalles("c1", cambios, "comp1")

    # Assert
    assert result.id == "c1"
    assert result.peso == 800.0
    assert result.numBultos == 15
    assert mock_cargas_crud.update.call_count == 1
    update_payload = mock_cargas_crud.update.call_args[0][2]
    assert update_payload["peso"] == 800.0
    assert update_payload["numBultos"] == 15
    assert "updatedAt" in update_payload


def test_update_carga_detalles_limpia_campos_con_null(service, mock_cargas_crud, carga_doc_dict):
    # Arrange
    doc_inicial = MagicMock(exists=True)
    doc_inicial.id = "c1"
    doc_inicial.to_dict.return_value = {**carga_doc_dict, "id": "c1", "companyId": "comp1"}

    doc_final = MagicMock(exists=True)
    doc_final.id = "c1"
    doc_final.to_dict.return_value = {**carga_doc_dict, "id": "c1", "companyId": "comp1"}
    mock_cargas_crud.get_by_id.side_effect = [doc_inicial, doc_final]

    cambios = CargaUpdateDetallesSchema(tipoEmbalaje=None)

    # Act
    result = service.update_carga_detalles("c1", cambios, "comp1")

    # Assert
    assert result.id == "c1"
    update_payload = mock_cargas_crud.update.call_args[0][2]
    assert update_payload["tipoEmbalaje"] is None

def test_update_carga_detalles_vacia_bultos_limpia_volumen_calculado(service, mock_cargas_crud, carga_doc_dict):
    # Arrange
    doc_inicial = MagicMock(exists=True)
    doc_inicial.id = "c1"
    doc_inicial.to_dict.return_value = {
        **carga_doc_dict,
        "id": "c1",
        "companyId": "comp1",
        "volumen": 100,
        "longitudLineal": 4.0,
    }

    doc_final = MagicMock(exists=True)
    doc_final.id = "c1"
    doc_final.to_dict.return_value = {
        **carga_doc_dict,
        "id": "c1",
        "companyId": "comp1",
        "numBultos": None,
        "volumen": None,
        "longitudLineal": None,
    }
    mock_cargas_crud.get_by_id.side_effect = [doc_inicial, doc_final]

    cambios = CargaUpdateDetallesSchema(numBultos=None)

    # Act
    result = service.update_carga_detalles("c1", cambios, "comp1")

    # Assert
    assert result.numBultos is None
    update_payload = mock_cargas_crud.update.call_args[0][2]
    assert update_payload["volumen"] is None
    assert update_payload["longitudLineal"] is None

