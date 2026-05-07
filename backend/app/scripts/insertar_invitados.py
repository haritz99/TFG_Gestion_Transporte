from __future__ import annotations

import argparse
import random
import uuid
from datetime import datetime, timezone, timedelta
from typing import Any, Dict

from ..firebase_config import db

DEFAULT_COMPANY_ID = "Oju2P1t0j6iBJ9llQGRK"

NOMBRES_COMERCIALES = [
    "Transportes Logisticos Paco", "Global Freight S.A.", "Cargas Rapidas S.L.",
    "EcoTrans", "Movilidad Total", "Logistica del Norte", "Rutas Express",
    "Servicios de Carga Plus", "TransLogistica 360", "Envíos Seguros"
]

EMAILS = [
    "contacto@paco.com", "info@global.es", "cargas@rapidas.net",
    "admin@ecotrans.it", "soporte@movilidad.com", "norte@logistica.com",
    "express@rutas.es", "plus@servicios.com", "360@translog.com", "seguros@envios.net"
]

def _crear_direccion():
    return {
        "calle": f"Calle Falsa {random.randint(1, 100)}",
        "ciudad": random.choice(["Madrid", "Barcelona", "Valencia"]),
        "provincia": random.choice(["Madrid", "Barcelona", "Valencia"]),
        "codigoPostal": f"{random.randint(28001, 28080)}",
        "pais": "España"
    }

def _crear_usuario_externo(company_id: str, index: int, rol: str, completo: bool) -> Dict[str, Any]:
    now = datetime.now(timezone.utc) - timedelta(days=random.randint(1, 10))
    uid = str(uuid.uuid4())

    # Datos base comunes (ExternalUserSchema)
    user_data = {
        "uid": uid,
        "email": f"{rol}{index}@empresa{index}.com",
        "rol": [rol],
        "companyId": company_id,
        "datosCompletos": completo,
        "createdAt": now,
        "updatedAt": now,
    }

    # Si los datos están completos, añadimos los campos específicos de la subclase
    if completo:
        user_data["nombreComercial"] = random.choice(NOMBRES_COMERCIALES) + f" {index}"
        user_data["telefono"] = f"600{random.randint(100000, 999999)}"

        if rol == "cliente":
            user_data.update({
                "cif": f"B{random.randint(10000000, 99999999)}",
                "personaContacto": f"Contacto {index}",
                "direccionFiscal": _crear_direccion(),
                "pedidos": []
            })
        else: # subcontratado
            user_data.update({
                "apellido": f"Apellido {index}",
                "nif": f"{random.randint(10000000, 99999999)}P",
                "numeroAutorizacion": f"AUT-{random.randint(1000, 9999)}",
                "cargasCedidas": [],
                "direccion": _crear_direccion()
            })

    return user_data

def insertar_datos(company_id: str, dry_run: bool = False) -> None:
    print(f"--- Limpiando usuarios antiguos para {company_id} ---")
    for coll in ["clientes", "subcontratados"]:
        docs = db.collection(coll).where("companyId", "==", company_id).stream()
        for doc in docs:
            if not dry_run:
                doc.reference.delete()

    print(f"--- Generando e insertando nuevos colaboradores ---")

    # Insertar 10 Clientes (5 completos, 5 incompletos)
    for i in range(10):
        completo = i < 5
        data = _crear_usuario_externo(company_id, i, "cliente", completo)
        if not dry_run:
            db.collection("clientes").document(data["uid"]).set(data)
        print(f"Cliente {i+1}/10 creado (Completo: {completo})")

    # Insertar 10 Subcontratados (5 completos, 5 incompletos)
    for i in range(10):
        completo = i < 5
        data = _crear_usuario_externo(company_id, i, "subcontratado", completo)
        if not dry_run:
            db.collection("subcontratados").document(data["uid"]).set(data)
        print(f"Subcontratado {i+1}/10 creado (Completo: {completo})")

    print(f"\nFinalizado (Dry-run: {dry_run})")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--company-id", default=DEFAULT_COMPANY_ID)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    insertar_datos(args.company_id, args.dry_run)

if __name__ == "__main__":
    main()

