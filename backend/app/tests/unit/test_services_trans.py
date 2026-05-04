import pytest
from unittest.mock import MagicMock, patch
from fastapi import HTTPException
from app.services.trans_service import TransService
from app.schemas.users import UserSchema

@pytest.fixture
def mock_trans_crud():
    return MagicMock(name="TransCRUD")

@pytest.fixture
def mock_user_crud():
    return MagicMock(name="UserCRUD")

@pytest.fixture
def service(mock_trans_crud, mock_user_crud):
    return TransService(crud=mock_trans_crud, user_crud=mock_user_crud)

@pytest.fixture
def mock_auth():
    with patch("app.services.trans_service.firebase_auth") as m:
        yield m

def test_trans_service_get_trans_ok(service, mock_user_crud):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "u1"
    mock_doc.to_dict.return_value = {
        "nombre": "A", "apellido": "B", "email": "a@test.com", "telefono": "123",
        "rol": ["transportista"], "permisosCond": ["C"], "estado": "sin_asignar",
        "companyId": "c1"
    }

    mock_user_crud.get_by_id.return_value = mock_doc

    res = service.get_trans("u1", "c1")
    assert res["uid"] == "u1"
    assert res["companyId"] == "c1"
    assert "transportista" in res["rol"]

def test_trans_service_get_trans_no_existe(service, mock_user_crud):
    mock_doc = MagicMock()
    mock_doc.exists = False
    mock_user_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.get_trans("ux", "c1")
    assert exc.value.status_code == 404

def test_trans_service_get_trans_otra_company(service, mock_user_crud):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "u1"
    mock_doc.to_dict.return_value = {
        "rol": ["transportista"], "companyId": "c2" # Otra comp
    }

    mock_user_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.get_trans("u1", "c1")
    assert exc.value.status_code == 404

def test_trans_service_get_trans_no_es_transportista(service, mock_user_crud):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.id = "u1"
    mock_doc.to_dict.return_value = {
        "rol": ["encargado"],
        "companyId": "c1"
    }

    mock_user_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.get_trans("u1", "c1")
    assert exc.value.status_code == 400

def test_trans_service_delete_trans_ok(service, mock_user_crud, mock_trans_crud, mock_auth):
    # Mockear user
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {
        "rol": ["transportista"], "companyId": "c1", "vehiculoId": "VEH123"
    }
    mock_user_crud.get_by_id.return_value = mock_doc

    # Mockear Vehiculo del transportista
    mock_veh_doc = MagicMock()
    mock_veh_doc.exists = True
    mock_trans_crud.get_vehiculo.return_value = mock_veh_doc

    res = service.delete_trans("u1", "c1")

    assert res["message"] == "Transportista eliminado con éxito y vehículo liberado"
    # Verificar acciones en BD
    mock_trans_crud.update_vehiculo.assert_called_once_with("VEH123", {"transportistaId": None})
    mock_auth.delete_user.assert_called_once_with("u1")
    mock_user_crud.delete.assert_called_once_with("u1")

def test_trans_service_delete_trans_sin_vehicular(service, mock_user_crud, mock_trans_crud, mock_auth):
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = {
        "rol": ["transportista"], "companyId": "c1", "vehiculoId": None
    }
    mock_user_crud.get_by_id.return_value = mock_doc

    res = service.delete_trans("u1", "c1")

    assert "vehículo liberado" not in res["message"]
    mock_trans_crud.update_vehiculo.assert_not_called()
    mock_auth.delete_user.assert_called_once_with("u1")
    mock_user_crud.delete.assert_called_once_with("u1")

def test_trans_service_get_all_paginated(service, mock_trans_crud):
    docs = []
    for i in range(3):
        doc = MagicMock()
        doc.id = f"u{i}"
        doc.to_dict.return_value = {
            "nombre": "N", "apellido": "A", "email": f"e{i}@e.c", "telefono": "123",
            "rol": ["transportista"], "permisosCond": ["C"], "companyId": "c1"
        }
        docs.append(doc)
    mock_trans_crud.get_all.return_value = docs

    res = service.get_all_trans("c1", solodis=False, limit=2)
    assert res.has_more is True
    assert len(res.items) == 2
    assert res.last_doc_id == "u1"

def test_trans_service_get_count(service, mock_trans_crud):
    mock_v = MagicMock()
    mock_v.value = 10
    mock_trans_crud.get_count.return_value = [[mock_v]]
    mock_v2 = MagicMock()
    mock_v2.value = 5
    mock_trans_crud.get_count_by_estado.return_value = [[mock_v2]]

    res = service.get_count_trans("c1")
    assert res.total_trans == 10
    assert res.en_ruta == 5

def test_trans_service_update_trans_ok(service, mock_user_crud, mock_auth):
    old_doc = MagicMock()
    old_doc.exists = True
    old_doc.to_dict.return_value = {
        "nombre": "Old", "apellido": "Old", "email": "old@old.com", "telefono": "123",
        "rol": ["transportista"], "permisosCond": ["C"], "companyId": "c1"
    }
    mock_user_crud.get_by_id.return_value = old_doc

    new_data = UserSchema(**{
        "uid": "u1", "nombre": "New", "apellido": "Old", "email": "new@new.com", "telefono": "123",
        "rol": ["transportista"], "permisosCond": ["C", "E"]
    })

    res = service.update_trans("u1", new_data, "c1")

    assert res.nombre == "New"
    assert res.email == "new@new.com"
    # Debe haber actualizado el email en auth porque cambió
    mock_auth.update_user.assert_called_once_with("u1", email="new@new.com")
    mock_user_crud.update.assert_called_once()

def test_trans_service_update_auth_error(service, mock_user_crud, mock_auth):
    old_doc = MagicMock(exists=True)
    old_doc.to_dict.return_value = {
        "nombre": "N", "apellido": "A", "email": "old@test.com", "telefono": "123456",
        "rol": ["transportista"], "permisosCond": ["C"], "companyId": "c1"
    }
    mock_user_crud.get_by_id.return_value = old_doc

    # Creamos clases de error falsas que hereden de Exception para que el bloque try/except del service no explote
    class MockEmailExists(Exception): pass
    mock_auth.EmailAlreadyExistsError = MockEmailExists
    mock_auth.update_user.side_effect = MockEmailExists("Email exists")

    new_data = UserSchema(**{
        "nombre": "New", "apellido": "A", "email": "fail@test.com", "telefono": "123456",
        "rol": ["transportista"], "permisosCond": ["C"]
    })

    with pytest.raises(HTTPException) as exc:
        service.update_trans("u1", new_data, "c1")
    assert exc.value.status_code == 400

def test_trans_service_get_count_error(service, mock_trans_crud):
    mock_trans_crud.get_count.side_effect = Exception("Firestore Timeout")
    with pytest.raises(HTTPException) as exc:
        service.get_count_trans("c1")
    assert exc.value.status_code == 500
