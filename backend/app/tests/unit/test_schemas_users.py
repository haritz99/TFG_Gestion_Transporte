import pytest
from pydantic import ValidationError
from app.schemas.users import UserSchema

def test_user_schema_valida_correctamente():
    payload = {
        "uid": "u1",
        "nombre": "Pepe",
        "apellido": "Garcia",
        "email": "pepe@test.com",
        "telefono": "+341234567",
        "rol": ["encargado"],
        "companyId": "comp1"
    }
    schema = UserSchema(**payload)
    assert schema.email == "pepe@test.com"
    assert schema.rol == ["encargado"]
    assert schema.estado == "sin_asignar" # Default

def test_user_schema_transportista_requiere_permisos():
    payload = {
        "nombre": "Ana",
        "apellido": "Perez",
        "email": "ana@test.com",
        "telefono": "123",
        "rol": ["transportista"],
        "companyId": "comp1"
    }
    # No permisosCond - should fail
    with pytest.raises(ValidationError):
        UserSchema(**payload)

    # With permisosCond - should pass
    payload["permisosCond"] = ["B", "C"]
    schema = UserSchema(**payload)
    assert schema.rol == ["transportista"]
    assert schema.permisosCond == ["B", "C"]

def test_user_schema_rol_deduplicado():
    payload = {
        "nombre": "Ana",
        "apellido": "Perez",
        "email": "ana@test.com",
        "telefono": "123",
        "rol": ["transportista", "transportista"], # repetido
        "permisosCond": ["C"],
        "companyId": "comp1"
    }
    schema = UserSchema(**payload)
    # Debe eliminar el duplicado
    assert len(schema.rol) == 1
    assert schema.rol[0] == "transportista"

