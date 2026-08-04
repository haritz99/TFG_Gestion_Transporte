from fastapi import Request
import pytest
from google.cloud import firestore
from app.dependencies.auth import get_current_user
from app.main import app

pytestmark = pytest.mark.integration

COLECCIONES_A_LIMPIAR = ["pedidos", "cargas", "empresas", "users", "subcontratados", "clientes", "tiposCarga", "counters",]

def _borrar_todas_las_colecciones(client: firestore.Client) -> None:
    for nombre_coleccion in COLECCIONES_A_LIMPIAR:
        _borrar_coleccion_recursiva(client.collection(nombre_coleccion))

def _borrar_coleccion_recursiva(coleccion_ref) -> None:
    for doc in coleccion_ref.stream():
        for subcoleccion in doc.reference.collections():
            _borrar_coleccion_recursiva(subcoleccion)
        doc.reference.delete()

@pytest.fixture(autouse=True)
def limpiar_firestore(firestore_client):
    _borrar_todas_las_colecciones(firestore_client)
    yield
    _borrar_todas_las_colecciones(firestore_client)


@pytest.fixture(autouse=True)
def override_auth():
    # Esto sobreescribe auth real para que no falle al probar contra auth real
    async def fake_current_user(request: Request):
        auth = request.headers.get("Authorization")

        if auth == "Bearer company-a-token":
            return {"uid": "user-a", "companyId": "company-a", "rol": ["encargado"],}

        if auth == "Bearer company-b-token":
            return {"uid": "user-b","companyId": "company-b","rol": ["encargado"],}

        raise Exception("Invalid token")

    app.dependency_overrides[get_current_user] = fake_current_user
    yield
    app.dependency_overrides.clear()

@pytest.fixture
def cliente_cli1(firestore_client):
    firestore_client.collection("clientes").document("cli1").set({
        "companyId": "company-a",
        "nombreComercial": "Cliente Test",
        "email": "cliente@gmail.com",
        "pedidos": [],
        "nif": "B12345678",
        "telefono": "600123123",
        "personaContacto": "Juan Pérez",
        "direccionFiscal": {
            "calle": "Calle Mayor 1",
            "ciudad": "Madrid",
            "provincia": "Madrid",
            "codigoPostal": "28001",
            "pais": "España",
        },
        "direccionCarga": {
            "calle": "Calle Mayor 1",
            "ciudad": "Madrid",
            "provincia": "Madrid",
            "codigoPostal": "28001",
            "pais": "España",
        },
    })

@pytest.fixture
def empresa_company_a(firestore_client):
    firestore_client.collection("empresas").document("company-a").set({
        "nombre": "Transporte Test",
        "razonSocial": "Transporte Test SL",
        "nif": "B11111111",
        "telefono": "600111111",
        "numAutorizacion": "MDP123456",
        "direccion": {
            "calle": "Calle Mayor 1",
            "ciudad": "Madrid",
            "provincia": "Madrid",
            "codigoPostal": "28001",
            "pais": "España",
        },
    })


@pytest.fixture
def tipo_carga_t1(firestore_client, tipo_carga_doc_dict):
    data = {
        **tipo_carga_doc_dict,
        "companyId": "company-a",
    }
    firestore_client.collection("tipos_carga").document("t1").set(data)

class TestFlujoPedidoCargaCartaPortePersistenciaCompleta:
    """
    Comprueba el flujo de generar pedido con carga y generar carta de porte de esa carga
    """
    def test_it_flujo_pedido_carga_carta_porte_persistencia_completa(self, client, firestore_client, auth_headers_company_a, fake_pedido, cliente_cli1, tipo_carga_t1, empresa_company_a):
        # Act 1: crear pedido vía endpoint real
        resp_pedido = client.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        assert resp_pedido.status_code == 201
        pedido_id = resp_pedido.json()["pedidoId"]

        pedido_doc = (firestore_client.collection("pedidos").document(pedido_id).get())
        assert pedido_doc.exists
        assert pedido_doc.to_dict()["companyId"] == "company-a"

        cargas_ref = (firestore_client.collection("pedidos").document(pedido_id).collection("cargas"))
        cargas_docs = list(cargas_ref.stream())
        assert len(cargas_docs) == 1
        carga_id = cargas_docs[0].id
        carga_data = cargas_docs[0].to_dict()
        assert carga_data["estado"] == "pendiente"

        resp_carta = client.get(f"/cargas/{carga_id}/carta-porte", headers=auth_headers_company_a)
        assert resp_carta.status_code == 200

        carga_actualizada = (firestore_client.collection("pedidos").document(pedido_id).collection("cargas").document(carga_id)
            .get()
            .to_dict()
        )
        assert carga_actualizada["cartaPorteSnapshot"] is not None
        assert carga_actualizada["carta_porte_url"]

    def test_it_falla_generar_carta_porte_sobre_carga_inexistente(self, client, auth_headers_company_a, cliente_cli1, tipo_carga_t1):
        resp = client.get("/cargas/carga-que-no-existe/carta-porte", headers=auth_headers_company_a)
        assert resp.status_code == 404


class TestAislamientoEmpresas:
    """
    Esto comprueba que una empresa no puede leer datos de otra, comprobando con pedidos
    """
    def test_it_no_permite_leer_pedido_de_otra_company(self,client,auth_headers_company_a,auth_headers_company_b,fake_pedido, cliente_cli1, tipo_carga_t1):
        # Arrange: pedido creado por company-a
        resp_creacion = client.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        assert resp_creacion.status_code == 201
        pedido_id = resp_creacion.json()["pedidoId"]

        # Act: company-b intenta leer el pedido de company-a
        resp_lectura = client.get(f"/pedidos/{pedido_id}", headers=auth_headers_company_b)
        assert resp_lectura.status_code == 404

    def test_it_no_permite_modificar_carga_de_otra_company(self,client,firestore_client,auth_headers_company_a,auth_headers_company_b,fake_pedido, cliente_cli1, tipo_carga_t1, empresa_company_a):
        resp_creacion = client.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        pedido_id = resp_creacion.json()["pedidoId"]
        carga_id = list(firestore_client.collection("pedidos").document(pedido_id).collection("cargas").stream())[0].id

        # Act: company-b intenta generar carta de porte sobre carga ajena
        resp = client.get(f"/cargas/{carga_id}/carta-porte", headers=auth_headers_company_b)
        assert resp.status_code == 404

class TestFlujoSnapshotCartaPortePersistidoEnCarga:
    """
    Verifica que cartaPorteSnapshot queda persistido.
    """

    def test_carta_porte_persistido_en_carga(self, client, firestore_client, auth_headers_company_a, fake_pedido, cliente_cli1, tipo_carga_t1, empresa_company_a):
        resp_pedido = client.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        pedido_id = resp_pedido.json()["pedidoId"]
        pedido_ref = firestore_client.collection("pedidos").document(pedido_id)
        carga_doc = list(pedido_ref.collection("cargas").stream())[0]
        carga_id = carga_doc.id

        resp_carta = client.get(f"/cargas/{carga_id}/carta-porte", headers=auth_headers_company_a)
        assert resp_carta.status_code == 200

        carga_actualizada = (pedido_ref.collection("cargas").document(carga_id).get().to_dict())
        snapshot = carga_actualizada["cartaPorteSnapshot"]

        assert snapshot["destinatarioNombre"] == fake_pedido["destinatarioNombre"]
        assert snapshot["destinatarioNif"] == fake_pedido["destinatarioNif"]
        assert carga_actualizada["carta_porte_url"]