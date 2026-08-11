import pytest
import math
from pydantic import ValidationError

from app.schemas.carga import CargaSchema
from app.schemas.pedido import CreatePedidoSchema


def test_carga_schema_validar_contra_pedido_rechaza_fuera_de_ventana(valid_carga_dict, create_pedido_dict):
    # Corresponde al test 10 de la lista backend.
    ahora = valid_carga_dict["fechaCarga"]
    carga = CargaSchema(**{**valid_carga_dict, "fechaCarga": ahora + __import__("datetime").timedelta(hours=1), "fechaDescarga": ahora + __import__("datetime").timedelta(hours=3)})
    pedido = CreatePedidoSchema(**{**create_pedido_dict, "fechaCarga": ahora + __import__("datetime").timedelta(days=1), "fechaDescarga": ahora + __import__("datetime").timedelta(days=2)})

    with pytest.raises(ValueError) as exc:
        carga.validar_contra_pedido(pedido)

    assert "fecha de carga" in str(exc.value).lower()


def test_carga_schema_validar_fechas_descarga_debe_ser_posterior(valid_carga_dict):
    # Corresponde al test 8 de la lista backend.
    with pytest.raises(ValidationError) as exc:
        CargaSchema(**{**valid_carga_dict, "fechaDescarga": valid_carga_dict["fechaCarga"]})

    assert "descarga" in str(exc.value).lower()
    assert "posterior" in str(exc.value).lower()


def test_carga_schema_calcula_volumen_y_longitud_lineal(valid_carga_dict):
    carga = CargaSchema(**{**valid_carga_dict, "largo": 1.2, "ancho": 0.8, "alto": 1.0})
    assert carga.volumen == pytest.approx(math.ceil(1.2 * 0.8 * 1.0 * 10))
    assert carga.longitudLineal == pytest.approx((1.2 * 0.8 / 2.4) * 10)


def test_carga_schema_apilable_divide_longitud_lineal(valid_carga_dict):
    carga = CargaSchema(**{**valid_carga_dict, "largo": 1.2, "ancho": 0.8, "alto": 1.0, "apilable": True})
    assert carga.volumen == pytest.approx(math.ceil(1.2 * 0.8 * 1.0 * 10))
    assert carga.longitudLineal == pytest.approx((1.2 * 0.8 / 2.4) * (10 / 2))


def test_carga_schema_granel_sin_bultos(valid_carga_dict):
    carga = CargaSchema(**{
        **valid_carga_dict,
        "tipoCarga": "granel",
        "numBultos": None,
        "largo": None,
        "ancho": None,
        "alto": None,
        "volumen": 30.0,
    })
    assert carga.numBultos is None
    assert carga.volumen == pytest.approx(30.0)
    assert carga.longitudLineal is None



