import pytest
from pydantic import ValidationError
from app.schemas.vehiculos import VehiculoSchema

def test_vehiculo_schema_valida_matricula():
    # Arrange
    valid_payload = {
        "matricula": "1234ABC",
        "marca": "Volvo",
        "modelo": "Transit",
        "capacidad": 10.0,
        "largo": 5.0,
        "ancho": 2.0,
        "alto": 2.5,
        "estado": "disponible",
        "interno": False,
        "companyId": "comp1"
    }

    # Act
    schema = VehiculoSchema(**valid_payload)

    # Assert
    assert schema.matricula == "1234ABC"

def test_vehiculo_schema_falla_matricula_invalida():
    invalid_payload = {
        "matricula": "XYZ1234", # Formato incorrecto
        "marca": "Volvo",
        "modelo": "Transit",
        "capacidad": 10.0,
        "largo": 5.0,
        "ancho": 2.0,
        "alto": 2.5,
        "estado": "disponible",
        "interno": False,
        "companyId": "comp1"
    }
    with pytest.raises(ValidationError):
        VehiculoSchema(**invalid_payload)

def test_vehiculo_schema_valida_estado_asignado():
    payload = {
        "matricula": "1234ABC",
        "marca": "Kia",
        "modelo": "V1",
        "capacidad": 15,
        "largo": 5, "ancho": 2, "alto": 2,
        "estado": "asignado",
        "interno": False,
        "companyId": "comp1"
    }
    # No transportistaId/Nombre - Should fail
    with pytest.raises(ValidationError):
        VehiculoSchema(**payload)

    # Valid
    payload["transportistaId"] = "u1"
    payload["transportistaNombre"] = "Juan Perez"
    schema = VehiculoSchema(**payload)
    assert schema.estado == "asignado"
    assert schema.transportistaId == "u1"

def test_vehiculo_schema_interno_requiere_remolque():
    payload = {
        "matricula": "1234ABC",
        "marca": "Kia",
        "modelo": "V1",
        "capacidad": 15,
        "largo": 5, "ancho": 2, "alto": 2,
        "estado": "disponible",
        "interno": True, # Requiere remolque
        "companyId": "comp1"
    }
    with pytest.raises(ValidationError):
        VehiculoSchema(**payload)

    # Añadimos remolque valido
    payload["matriculaRemolque"] = "9999XYZ"
    schema = VehiculoSchema(**payload)
    assert schema.matriculaRemolque == "9999XYZ"

