from __future__ import annotations

import argparse
from datetime import datetime, timezone

from ..firebase_config import db

DEFAULT_COMPANY_ID = "Oju2P1t0j6iBJ9llQGRK"
CLIENTE_ID = "EbmliX5MxPgRYKE4smXD"

TIPOS_CARGA = [
    {
        "nombre": "Palé euroestándar",
        "descripcion": "Palé de madera 120×80cm, apilable hasta 3 unidades",
        "tipoCarga": "bultos",
        "apilable": True,
        "mercancia": "General",
        "tipoEmbalaje": "Palé",
        "numBultos": 1,
        "peso": 800.0,
        "pesoMax": 1000.0,
        "precio": 45.0,
        "largo": 1.2,
        "ancho": 0.8,
        "alto": 1.5,
        "origen": "Madrid",
        "destino": "Barcelona",
    },
    {
        "nombre": "Contenedor 20ft",
        "descripcion": "Contenedor estándar de 20 pies para carga general",
        "tipoCarga": "bultos",
        "apilable": False,
        "mercancia": "General",
        "tipoEmbalaje": "Contenedor",
        "numBultos": 10,
        "peso": 5000.0,
        "pesoMax": 21700.0,
        "precio": 320.0,
        "largo": 5.9,
        "ancho": 2.35,
        "alto": 2.39,
        "origen": "Valencia",
        "destino": "Bilbao",
    },
    {
        "nombre": "Carga frigorífica",
        "descripcion": "Mercancía en temperatura controlada entre 2°C y 8°C",
        "tipoCarga": "bultos",
        "apilable": False,
        "mercancia": "Alimentos",
        "tipoEmbalaje": "Cajas",
        "numBultos": 20,
        "peso": 1500.0,
        "pesoMax": 3000.0,
        "precio": 180.0,
        "largo": 2.4,
        "ancho": 1.2,
        "alto": 1.8,
        "origen": "Zaragoza",
        "destino": "Sevilla",
    },
    {
        "nombre": "Paquetería express",
        "descripcion": "Envíos urgentes de pequeño formato",
        "tipoCarga": "bultos",
        "apilable": True,
        "mercancia": "Paquetería",
        "tipoEmbalaje": "Caja de cartón",
        "numBultos": 50,
        "peso": 200.0,
        "pesoMax": 500.0,
        "precio": 25.0,
        "largo": 0.6,
        "ancho": 0.4,
        "alto": 0.4,
        "origen": "Barcelona",
        "destino": "Madrid",
    },
    {
        "nombre": "Áridos a granel",
        "descripcion": "Carga suelta sin embalaje (arena, grava, cemento)",
        "tipoCarga": "granel",
        "apilable": False,
        "mercancia": "Áridos",
        "tipoEmbalaje": "A granel",
        "peso": 22000.0,
        "pesoMax": 24000.0,
        "precio": 250.0,
        "volumen": 14.0,
        "origen": "Murcia",
        "destino": "Alicante",
    },
    {
        "nombre": "Gasóleo",
        "descripcion": "Líquido a granel en cisterna (no apilable)",
        "tipoCarga": "liquido",
        "apilable": False,
        "mercancia": "Gasóleo",
        "tipoEmbalaje": "Cisterna",
        "peso": 18000.0,
        "pesoMax": 20000.0,
        "precio": 300.0,
        "volumen": 20.0,
        "origen": "Cartagena",
        "destino": "Madrid",
    },
]


def insertar_tipos_carga(company_id: str, dry_run: bool = False) -> None:
    col_ref = db.collection("tipos_carga")
    now = datetime.now(timezone.utc)

    # 1 — Limpiar tipos existentes de esta compañía y cliente
    print(f"--- Limpiando tipos de carga existentes para {company_id} ---")
    docs = (col_ref
            .where("companyId", "==", company_id)
            .where("clienteId", "==", CLIENTE_ID)
            .stream())

    count_deleted = 0
    for doc in docs:
        if not dry_run:
            doc.reference.delete()
        count_deleted += 1
    print(f"Eliminados {count_deleted} tipos de carga.")

    # 2 — Insertar tipos
    print("--- Insertando nuevos tipos de carga ---")
    for i, tipo in enumerate(TIPOS_CARGA):
        doc_data = {
            **tipo,
            "companyId": company_id,
            "clienteId": CLIENTE_ID,
            "createdAt": now,
            "updatedAt": now,
        }
        doc_id = f"TIPO-{i + 1:03d}"
        if not dry_run:
            col_ref.document(doc_id).set(doc_data)
        print(f"  [{doc_id}] {tipo['nombre']} — {tipo['precio']}€")

    print(f"\nFinalizado: {len(TIPOS_CARGA)} tipos insertados (Dry-run: {dry_run})")


def main() -> None:
    parser = argparse.ArgumentParser(description="Inserta tipos de carga de prueba")
    parser.add_argument("--company-id", default=DEFAULT_COMPANY_ID)
    parser.add_argument("--dry-run", action="store_true", help="No escribe en Firestore")
    args = parser.parse_args()

    insertar_tipos_carga(company_id=args.company_id, dry_run=args.dry_run)


if __name__ == "__main__":
    main()