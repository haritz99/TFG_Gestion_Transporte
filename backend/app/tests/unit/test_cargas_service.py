import pytest
import datetime
from unittest.mock import MagicMock
from fastapi import HTTPException
from app.services.cargas_service import CargasService
from app.schemas.carga import CargaSchema, EstadoCarga
from app.schemas.pedido import PedidoSchema

@pytest.fixture
def mock_cargas_crud():
    return MagicMock(name="CargasCRUD")

@pytest.fixture
def service(mock_cargas_crud):
    return CargasService(crud=mock_cargas_crud)

@pytest.fixture
def valid_carga_dict():
    ahora = datetime.datetime.now(datetime.timezone.utc)
    return {
        "pedidoId": "p1",
        "origen": "Madrid",
        "destino": "Barcelona",
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

def test_cargas_service_create_carga_valida(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    carga = CargaSchema(**valid_carga_dict)
    from app.schemas.pedido import CreatePedidoSchema, AsignacionCargaSchema
    pedido = CreatePedidoSchema(
        descripcion="T",
        clienteId="cli1",
        companyId="comp1",
        fechaCarga=carga.fechaCarga - datetime.timedelta(hours=1),
        fechaDescarga=carga.fechaDescarga + datetime.timedelta(hours=1),
        cargas=[AsignacionCargaSchema(tipoCargaId="t1")]
    )
    mock_cargas_crud.create_carga_doc.return_value = "new_c_id"

    # Act
    res = service.create_carga(carga, pedido, "comp1")

    # Assert
    assert res.id == "new_c_id"
    assert res.clienteId == "cli1"

def test_cargas_service_create_carga_error_validacion(service, valid_carga_dict):
    pass

def test_cargas_service_assign_carga_ok(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc_carga = MagicMock(exists=True)
    mock_doc_carga.id = "c1"
    mock_doc_carga.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc_carga

    mock_doc_trans = MagicMock(exists=True)
    mock_doc_trans.to_dict.return_value = {"companyId": "comp1", "rol": ["transportista"]}
    mock_cargas_crud.get_trans_doc.return_value = mock_doc_trans

    # Act
    res = service.assign_carga_transportista("c1", "t1", "comp1")

    # Assert
    assert res.transportistaId == "t1"
    assert res.estado == EstadoCarga.ASIGNADO

def test_cargas_service_assign_carga_no_trans(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc_carga = MagicMock(exists=True)
    mock_doc_carga.id = "c1"
    mock_doc_carga.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc_carga

    mock_doc_trans = MagicMock(exists=True)
    mock_doc_trans.to_dict.return_value = {"companyId": "comp1", "rol": ["encargado"]}
    mock_cargas_crud.get_trans_doc.return_value = mock_doc_trans

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.assign_carga_transportista("c1", "t1", "comp1")
    assert exc.value.status_code == 403

def test_cargas_service_delete_carga_ok(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock(exists=True)
    mock_doc.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc

    # Act
    service.delete_carga("c1", "comp1")

    # Assert
    mock_cargas_crud.delete_carga_doc.assert_called_once_with("c1")

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

def test_cargas_service_assign_carga_not_found(service, mock_cargas_crud):
    # Arrange
    mock_doc = MagicMock(exists=False)
    mock_cargas_crud.get_carga_doc.return_value = mock_doc

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.assign_carga_transportista("c_inexistente", "t1", "comp1")
    assert exc.value.status_code == 404

def test_cargas_service_assign_transportista_not_found(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc_carga = MagicMock(exists=True)
    mock_doc_carga.id = "c1"
    mock_doc_carga.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc_carga

    mock_doc_trans = MagicMock(exists=False)
    mock_cargas_crud.get_trans_doc.return_value = mock_doc_trans

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.assign_carga_transportista("c1", "t_inexistente", "comp1")
    assert exc.value.status_code == 404

def test_cargas_service_update_carga_ok(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock(exists=True)
    mock_doc.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc

    carga_upd = CargaSchema(**valid_carga_dict)
    carga_upd.mercancia = "Nueva Mercancia"

    pedido = PedidoSchema(
        id="p1", clienteId="cli1", descripcion="T", companyId="comp1",
        fechaCarga=carga_upd.fechaCarga - datetime.timedelta(hours=1), 
        fechaDescarga=carga_upd.fechaDescarga + datetime.timedelta(hours=1),
        origenes=["Madrid"], destinos=["Barcelona"]
    )

    # Act
    res = service.update_carga("c1", carga_upd, pedido, "comp1")

    # Assert
    assert res.mercancia == "Nueva Mercancia"
    mock_cargas_crud.update_carga_doc.assert_called_once()

def test_cargas_service_update_carga_not_found(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock(exists=False)
    mock_cargas_crud.get_carga_doc.return_value = mock_doc
    carga_upd = CargaSchema(**valid_carga_dict)
    pedido = MagicMock()

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.update_carga("c1", carga_upd, pedido, "comp1")
    assert exc.value.status_code == 404

def test_cargas_service_update_carga_company_mismatch(service, mock_cargas_crud, valid_carga_dict):
    # Arrange
    mock_doc = MagicMock(exists=True)
    valid_carga_dict["companyId"] = "comp_otra"
    mock_doc.to_dict.return_value = valid_carga_dict
    mock_cargas_crud.get_carga_doc.return_value = mock_doc

    carga_upd = CargaSchema(**valid_carga_dict)
    pedido = MagicMock()

    # Act & Assert
    with pytest.raises(HTTPException) as exc:
        service.update_carga("c1", carga_upd, pedido, "comp1")
    assert exc.value.status_code == 403
