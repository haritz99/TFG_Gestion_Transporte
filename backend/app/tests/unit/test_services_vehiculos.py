import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException
from app.services.vehiculo_service import VehiculoService
from app.schemas.vehiculos import VehiculoSchema

@pytest.fixture
def mock_crud():
    with patch('app.services.vehiculo_service.VehiculoCRUD') as mock:
        yield mock.return_value

@pytest.fixture
def service(mock_crud):
    # Ya inyectamos el mock mediante el parche
    return VehiculoService()

def test_vehiculo_service_get_by_id_existe(service, mock_crud):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "1234ABC"
    mock_doc.to_dict.return_value = {
        "marca": "Ford", "modelo": "Tr", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
        "estado": "disponible", "interno": False, "companyId": "c1"
    }
    mock_crud.get_by_id.return_value = mock_doc

    result = service.get_by_id("1234ABC", "c1")
    assert result.matricula == "1234ABC"
    assert result.companyId == "c1"
    mock_crud.get_by_id.assert_called_once_with("1234ABC")

def test_vehiculo_service_get_by_id_no_existe_falla(service, mock_crud):
    mock_doc = MagicMock()
    mock_doc.exists = False
    mock_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.get_by_id("1234ABC", "c1")

    assert exc.value.status_code == 404

def test_vehiculo_service_get_by_id_different_company(service, mock_crud):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "1234ABC"
    mock_doc.to_dict.return_value = {
        "marca": "Ford", "modelo": "Tr", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
        "estado": "disponible", "interno": False, "companyId": "c2" # Otra comp
    }
    mock_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.get_by_id("1234ABC", "req_comp") # Compañía diferente

    assert exc.value.status_code == 403

def test_vehiculo_service_create_ok(service, mock_crud):
    vehiculo_payload = VehiculoSchema(**{
        "matricula": "9999XYZ", "marca": "K", "modelo": "N", "capacidad": 10,
        "largo": 5, "ancho": 2, "alto": 2, "estado": "disponible", "interno": False
    })

    mock_doc = MagicMock()
    mock_doc.exists = False
    mock_crud.get_by_id.return_value = mock_doc

    mock_batch = MagicMock()
    mock_crud.get_batch.return_value = mock_batch

    result = service.create(vehiculo_payload, "comp1")

    assert result.companyId == "comp1"
    mock_crud.set_vehiculo.assert_called_once()
    mock_crud.commit_batch.assert_called_once_with(mock_batch)

def test_vehiculo_service_create_ya_existe(service, mock_crud):
    vehiculo_payload = VehiculoSchema(**{
        "matricula": "9999XYZ", "marca": "K", "modelo": "N", "capacidad": 10,
        "largo": 5, "ancho": 2, "alto": 2, "estado": "disponible", "interno": False
    })

    mock_doc = MagicMock()
    mock_doc.exists = True # Coche existe
    mock_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.create(vehiculo_payload, "comp1")

    assert exc.value.status_code == 409

def test_vehiculo_service_assign_ok(service, mock_crud):
    # Mock vehiculo
    mock_veh_doc = MagicMock()
    mock_veh_doc.exists = True
    mock_veh_doc.id = "1111AAA"
    mock_veh_doc.to_dict.return_value = {
        "marca": "F", "modelo": "X", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
        "estado": "disponible", "interno": False, "companyId": "c1"
    }
    mock_usr_doc = MagicMock()
    mock_usr_doc.exists = True
    mock_usr_doc.to_dict.return_value = {
        "nombre": "Pepe", "apellido": "G"
    }

    mock_crud.get_by_id.return_value = mock_veh_doc
    mock_crud.get_user_by_id.return_value = mock_usr_doc

    mock_batch = MagicMock()
    mock_crud.get_batch.return_value = mock_batch

    res = service.assign("1111AAA", "usr1", "c1")

    assert res.estado == "asignado"
    assert res.transportistaNombre == "Pepe G"
    mock_crud.update_vehiculo.assert_called_once()
    mock_crud.update_user_vehiculo_id.assert_called_once()
    mock_crud.commit_batch.assert_called_once_with(mock_batch)

def test_vehiculo_service_get_all_paginated(service, mock_crud):
    # Setup
    docs = []
    for i in range(3):
        doc = MagicMock()
        doc.id = f"100{i}ABC"
        doc.to_dict.return_value = {
            "marca": "F", "modelo": "M", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
            "estado": "disponible", "interno": False, "companyId": "c1"
        }
        docs.append(doc)
    mock_crud.get_all.return_value = docs

    # Act
    res = service.get_all("c1", limit=2)
    
    # Assert
    assert res.has_more is True
    assert len(res.items) == 2
    assert res.last_doc_id == "1001ABC"  # second item id

def test_vehiculo_service_update(service, mock_crud):
    old_doc = MagicMock()
    old_doc.exists = True
    old_doc.id = "1234ABC"
    old_doc.to_dict.return_value = {
        "marca": "F", "modelo": "M", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
        "estado": "disponible", "interno": False, "companyId": "c1", "transportistaId": None, "transportistaNombre": None
    }
    mock_crud.get_by_id.return_value = old_doc
    mock_batch = MagicMock()
    mock_crud.get_batch.return_value = mock_batch

    new_data = VehiculoSchema(**{
        "matricula": "1234ABC", "marca": "F", "modelo": "Mod", "capacidad": 10,
        "largo": 5, "ancho": 2, "alto": 2, "estado": "asignado", "interno": False,
        "transportistaId": "u2", "transportistaNombre": "Nuevo Juan"
    })

    res = service.update("1234ABC", new_data, "c1")
    assert res.transportistaId == "u2"
    
    # old_tid=None, new_tid='u2'
    mock_crud.update_user_vehiculo_id.assert_called_once_with(mock_batch, "u2", "1234ABC")

def test_vehiculo_service_delete(service, mock_crud):
    doc = MagicMock()
    doc.exists = True
    doc.id = "1234ABC"
    doc.to_dict.return_value = {
        "marca": "F", "modelo": "M", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
        "estado": "asignado", "interno": False, "companyId": "c1", "transportistaId": "u1", "transportistaNombre": "Juan"
    }
    mock_crud.get_by_id.return_value = doc
    mock_batch = MagicMock()
    mock_crud.get_batch.return_value = mock_batch

    service.delete("1234ABC", "c1")
    
    mock_crud.delete_vehiculo.assert_called_once_with(mock_batch, "1234ABC")
    mock_crud.update_user_vehiculo_id.assert_called_once_with(mock_batch, "u1", None)

def test_vehiculo_service_get_count(service, mock_crud):
    mock_v = MagicMock()
    mock_v.value = 10
    mock_crud.get_count.return_value = [[mock_v]]
    
    mock_v2 = MagicMock()
    mock_v2.value = 5
    mock_crud.get_count_by_estado.return_value = [[mock_v2]]

    res = service.get_count("c1")
    
    assert res.totalVehiculos == 10
    assert res.asignados == 5

def test_vehiculo_service_delete_not_found(service, mock_crud):
    mock_doc = MagicMock(exists=False)
    mock_crud.get_by_id.return_value = mock_doc
    with pytest.raises(HTTPException) as exc:
        service.delete("9999ZZZ", "c1")
    assert exc.value.status_code == 404

def test_vehiculo_service_assign_transportista_not_found(service, mock_crud):
    mock_veh = MagicMock(exists=True, id="1234ABC")
    mock_veh.to_dict.return_value = {
        "marca": "F", "modelo": "X", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
        "estado": "disponible", "interno": False, "companyId": "c1"
    }
    mock_crud.get_by_id.return_value = mock_veh
    mock_user = MagicMock(exists=False)
    mock_crud.get_user_by_id.return_value = mock_user
    with pytest.raises(HTTPException) as exc:
        service.assign("1234ABC", "usr_fantasma", "c1")
    assert exc.value.status_code == 404

def test_vehiculo_service_update_db_error(service, mock_crud):
    mock_doc = MagicMock(exists=True, id="1234ABC")
    mock_doc.to_dict.return_value = {
        "marca": "F", "modelo": "M", "capacidad": 10, "largo": 5, "ancho": 2, "alto": 2,
        "estado": "disponible", "interno": False, "companyId": "c1",
        "transportistaId": None, "transportistaNombre": None
    }
    mock_crud.get_by_id.return_value = mock_doc
    mock_crud.commit_batch.side_effect = Exception("DB Error")

    new_data = VehiculoSchema(**{
        "matricula": "1234ABC", "marca": "F", "modelo": "Mod", "capacidad": 10,
        "largo": 5, "ancho": 2, "alto": 2, "estado": "asignado", "interno": False,
        "transportistaId": "u2", "transportistaNombre": "Juan"
    })
    with pytest.raises(HTTPException) as exc:
        service.update("1234ABC", new_data, "c1")
    assert exc.value.status_code == 500

