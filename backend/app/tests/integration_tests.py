import pytest


pytestmark = pytest.mark.integration


class TestFlujoPedidoCargaCartaPortePersistenciaCompleta:
    """
    Comprueba el flujo de generar pedido con carga y generar carta de porte de esa carga
    """

    def test_it_flujo_pedido_carga_carta_porte_persistencia_completa(self, client_integration, firestore_client, auth_headers_company_a, fake_pedido):
        # Act 1: crear pedido vía endpoint real
        resp_pedido = client_integration.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        assert resp_pedido.status_code == 201
        pedido_id = resp_pedido.json()["id"]

        pedido_doc = (firestore_client.collection("pedidos").document(pedido_id).get())
        assert pedido_doc.exists
        assert pedido_doc.to_dict()["companyId"] == "company-a"

        cargas_ref = (firestore_client.collection("pedidos").document(pedido_id).collection("cargas"))
        cargas_docs = list(cargas_ref.stream())
        assert len(cargas_docs) == 1
        carga_id = cargas_docs[0].id
        carga_data = cargas_docs[0].to_dict()
        assert carga_data["estado"] == "pendiente"

        # generar carta de porte vía endpoint real
        resp_carta = client_integration.post(f"/cargas/{carga_id}/carta-porte", headers=auth_headers_company_a)
        assert resp_carta.status_code == 201

        carga_actualizada = (firestore_client.collection("pedidos").document(pedido_id).collection("cargas").document(carga_id)
            .get()
            .to_dict()
        )
        assert carga_actualizada["cartaPorteSnapshot"] is not None
        assert carga_actualizada["cartaPorteSnapshot"]["pdfUrl"]
        assert carga_actualizada["estado"] != "pendiente"

    def test_it_falla_generar_carta_porte_sobre_carga_inexistente(self, client_integration, auth_headers_company_a):
        resp = client_integration.post("/cargas/carga-que-no-existe/carta-porte", headers=auth_headers_company_a)
        assert resp.status_code == 404


class TestAislamientoEmpresas:
    """
    Esto comprueba que una empresa no puede leer datos de otra, comprobando con pedidos
    """
    def test_it_no_permite_leer_pedido_de_otra_company(self,client_integration,auth_headers_company_a,auth_headers_company_b,fake_pedido,):
        # Arrange: pedido creado por company-a
        resp_creacion = client_integration.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        assert resp_creacion.status_code == 201
        pedido_id = resp_creacion.json()["id"]

        # Act: company-b intenta leer el pedido de company-a
        resp_lectura = client_integration.get(f"/pedidos/{pedido_id}", headers=auth_headers_company_b)

        assert resp_lectura.status_code == 403

    def test_it_no_permite_modificar_carga_de_otra_company(self,client_integration,firestore_client,auth_headers_company_a,auth_headers_company_b,fake_pedido):
        resp_creacion = client_integration.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        pedido_id = resp_creacion.json()["id"]
        carga_id = list(firestore_client.collection("pedidos").document(pedido_id).collection("cargas").stream())[0].id

        # Act: company-b intenta generar carta de porte sobre carga ajena
        resp = client_integration.post(f"/cargas/{carga_id}/carta-porte", headers=auth_headers_company_b)

        assert resp.status_code == 403

        # Assert: la carga de company-a no debe haberse alterado
        carga_tras_intento = (firestore_client.collection("pedidos").document(pedido_id).collection("cargas").document(carga_id)
            .get()
            .to_dict()
        )
        assert carga_tras_intento.get("cartaPorteSnapshot") is None


class TestFlujoSnapshotCartaPortePersistidoEnCarga:
    """
    Verifica que cartaPorteSnapshot queda persistido.
    """

    def test_carta_porte_persistido_en_carga(self, client_integration, firestore_client, auth_headers_company_a, fake_pedido):
        resp_pedido = client_integration.post("/pedidos", json=fake_pedido, headers=auth_headers_company_a)
        pedido_id = resp_pedido.json()["id"]
        pedido_ref = firestore_client.collection("pedidos").document(pedido_id)
        carga_doc = list(pedido_ref.collection("cargas").stream())[0]
        carga_id = carga_doc.id

        resp_carta = client_integration.post(f"/cargas/{carga_id}/carta-porte", headers=auth_headers_company_a)
        assert resp_carta.status_code == 201

        carga_actualizada = (pedido_ref.collection("cargas").document(carga_id).get().to_dict())
        snapshot = carga_actualizada["cartaPorteSnapshot"]

        assert snapshot["destinatarioNombre"] == fake_pedido["destinatarioNombre"]
        assert snapshot["destinatarioNif"] == fake_pedido["destinatarioNif"]
        assert snapshot["carta_porte_url"]