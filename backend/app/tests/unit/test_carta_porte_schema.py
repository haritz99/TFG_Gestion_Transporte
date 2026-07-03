from app.services.carta_porte_service import CartaPorteService


# Test 17: test_carta_porte_camel_to_snake_convierte_claves_mixtas
def test_carta_porte_camel_to_snake_convierte_claves_mixtas():
    # Arrange
    payload = {
        "clienteNombre": "Cliente",
        "clienteNif": "B12345678",
        "subContratadoNombre": "Sub S.L.",
        "subVehiculoMatricula": "1234ABC",
        "nestedValue": {
            "fechaCarga": "2026-01-01",
            "horaInicio": "08:00",
        },
    }

    # Act
    normalizado = CartaPorteService._normalize_for_template(payload)

    # Assert
    assert "cliente_nombre" in normalizado
    assert "cliente_nif" in normalizado
    assert "sub_contratado_nombre" in normalizado
    assert "sub_vehiculo_matricula" in normalizado
    assert normalizado["nested_value"]["fecha_carga"] == "2026-01-01"
    assert normalizado["nested_value"]["hora_inicio"] == "08:00"

