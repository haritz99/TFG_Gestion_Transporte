import pytest
from app.schemas.users import UserSchema
from pydantic import ValidationError

def test_contract_flutter_create_transportista():
    # 1. Este es exactamente el diccionario que construye Flutter en transportista_service.dart
    flutter_payload = {
      'nombre': 'Carlos',
      'apellido': 'Sainz',
      'email': 'carlos@empresa.com',
      'telefono': '+34123456789',
      'rol': ['transportista'],
      'permisosCond': ['C', 'C+E'],
    }

    # 2. Se lo empujamos directamente a Pydantic
    try:
        user = UserSchema(**flutter_payload)
    except ValidationError as e:
        pytest.fail(f"El contrato se ha roto. Pydantic rechaza el payload de Flutter. Errores: {e}")

    assert user.companyId is None, "Debe venir nulo, el Router lo rellenara luego con el Token"

def test_contract_flutter_rompe_contrato():
    flutter_payload_roto = {
      'nombre': 'Carlos',
      'apellido': 'Sainz',
      'email': 'carlos@empresa.com',
      'telefono': '+34123456789',
      'rol': ['transportista'],
    }

    with pytest.raises(ValidationError) as exc_info:
        UserSchema(**flutter_payload_roto)

    assert "permisosCond" in str(exc_info.value), "Pydantic debe chillar porque Flutter no mando los permisos"

