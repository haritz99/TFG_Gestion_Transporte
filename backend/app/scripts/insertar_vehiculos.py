from __future__ import annotations

import argparse
from typing import Any, Dict, List

from ..firebase_config import db
from ..schemas.vehiculos import VehiculoSchema

DEFAULT_COMPANY_ID = "bBuVP0Uvoi2bC5ZAGXAt"


def _seed_vehiculos() -> List[Dict[str, Any]]:
    """Datos de ejemplo para poblar Firestore con vehículos válidos."""
    return [
        {
            "matricula": "1234ABC",
            "marca": "Mercedes",
            "modelo": "Actros 1845",
            "capacidad": 18.0,
            "largo": 6.8,
            "ancho": 2.5,
            "alto": 3.6,
            "estado": "disponible",
            "interno": True,
            "matriculaRemolque": "5678DEF",
            "transportistaId": None,
        },
        {
            "matricula": "2345BCD",
            "marca": "Volvo",
            "modelo": "FH 500",
            "capacidad": 20.0,
            "largo": 7.2,
            "ancho": 2.5,
            "alto": 3.7,
            "estado": "asignado",
            "interno": True,
            "matriculaRemolque": "6789EFG",
            "transportistaId": "uid_trans_001",
            "transportistaNombre": "Juan Perez",
        },
        {
            "matricula": "3456CDE",
            "marca": "Scania",
            "modelo": "R 450",
            "capacidad": 19.0,
            "largo": 7.0,
            "ancho": 2.5,
            "alto": 3.8,
            "estado": "disponible",
            "interno": False,
            "matriculaRemolque": None,
            "transportistaId": None,
        },
        {
            "matricula": "4567DEF",
            "marca": "MAN",
            "modelo": "TGX 18.510",
            "capacidad": 21.0,
            "largo": 7.1,
            "ancho": 2.5,
            "alto": 3.9,
            "estado": "asignado",
            "interno": False,
            "matriculaRemolque": None,
            "transportistaId": "uid_trans_002",
            "transportistaNombre": "Maria Lopez",
        },
        {
            "matricula": "5678EFG",
            "marca": "Iveco",
            "modelo": "S-Way",
            "capacidad": 17.5,
            "largo": 6.9,
            "ancho": 2.45,
            "alto": 3.5,
            "estado": "disponible",
            "interno": True,
            "matriculaRemolque": "7890FGH",
            "transportistaId": None,
        },
        {
            "matricula": "6789FGH",
            "marca": "DAF",
            "modelo": "XF 480",
            "capacidad": 22.0,
            "largo": 7.3,
            "ancho": 2.5,
            "alto": 3.85,
            "estado": "asignado",
            "interno": True,
            "matriculaRemolque": "8901GHI",
            "transportistaId": "uid_trans_003",
            "transportistaNombre": "Carlos Ruiz",
        },
        {
            "matricula": "7890GHI",
            "marca": "Renault",
            "modelo": "T High 480",
            "capacidad": 18.5,
            "largo": 7.0,
            "ancho": 2.5,
            "alto": 3.75,
            "estado": "disponible",
            "interno": False,
            "matriculaRemolque": None,
            "transportistaId": None,
        },
        {
            "matricula": "8901HIJ",
            "marca": "Mercedes",
            "modelo": "Arocs 1846",
            "capacidad": 23.0,
            "largo": 7.4,
            "ancho": 2.5,
            "alto": 3.9,
            "estado": "asignado",
            "interno": True,
            "matriculaRemolque": "9012IJK",
            "transportistaId": "uid_trans_004",
            "transportistaNombre": "Ana Gomez",
        },
        {
            "matricula": "9012IJK",
            "marca": "Volvo",
            "modelo": "FMX 460",
            "capacidad": 16.0,
            "largo": 6.6,
            "ancho": 2.45,
            "alto": 3.45,
            "estado": "disponible",
            "interno": True,
            "matriculaRemolque": "0123JKL",
            "transportistaId": None,
        },
        {
            "matricula": "0123JKL",
            "marca": "Scania",
            "modelo": "S 500",
            "capacidad": 24.0,
            "largo": 7.5,
            "ancho": 2.5,
            "alto": 3.95,
            "estado": "asignado",
            "interno": False,
            "matriculaRemolque": None,
            "transportistaId": "uid_trans_005",
            "transportistaNombre": "Pedro Martin",
        },
        {
            "matricula": "1357KLM",
            "marca": "MAN",
            "modelo": "TGS 18.470",
            "capacidad": 19.5,
            "largo": 7.1,
            "ancho": 2.5,
            "alto": 3.8,
            "estado": "disponible",
            "interno": False,
            "matriculaRemolque": None,
            "transportistaId": None,
        },
        {
            "matricula": "2468LMN",
            "marca": "Iveco",
            "modelo": "Eurocargo",
            "capacidad": 12.0,
            "largo": 6.2,
            "ancho": 2.4,
            "alto": 3.2,
            "estado": "disponible",
            "interno": True,
            "matriculaRemolque": "3579MNO",
            "transportistaId": None,
        },
        {
            "matricula": "3579MNO",
            "marca": "DAF",
            "modelo": "CF 450",
            "capacidad": 21.5,
            "largo": 7.2,
            "ancho": 2.5,
            "alto": 3.85,
            "estado": "asignado",
            "interno": True,
            "matriculaRemolque": "4680NOP",
            "transportistaId": "uid_trans_006",
            "transportistaNombre": "Lucia Diaz",
        },
        {
            "matricula": "4680NOP",
            "marca": "Renault",
            "modelo": "D Wide",
            "capacidad": 14.0,
            "largo": 6.4,
            "ancho": 2.45,
            "alto": 3.35,
            "estado": "disponible",
            "interno": False,
            "matriculaRemolque": None,
            "transportistaId": None,
        },
        {
            "matricula": "5791OPQ",
            "marca": "Mercedes",
            "modelo": "Antos 1836",
            "capacidad": 17.0,
            "largo": 6.7,
            "ancho": 2.45,
            "alto": 3.5,
            "estado": "asignado",
            "interno": False,
            "matriculaRemolque": None,
            "transportistaId": "uid_trans_007",
            "transportistaNombre": "Diego Sanchez",
        },
    ]


def _build_payloads(company_id: str) -> List[Dict[str, Any]]:
    payloads: List[Dict[str, Any]] = []
    for raw in _seed_vehiculos():
        candidate = {**raw, "companyId": company_id}
        # Valida contra el schema para asegurar consistencia antes de escribir.
        validated = VehiculoSchema(**candidate)
        payloads.append(validated.model_dump())
    return payloads


def insertar_vehiculos(company_id: str, dry_run: bool = False, replace_existing: bool = False) -> None:
    payloads = _build_payloads(company_id)
    vehiculos_ref = db.collection("vehiculos")

    inserted = 0
    updated = 0
    skipped = 0

    for payload in payloads:
        matricula = payload["matricula"].upper()
        doc_ref = vehiculos_ref.document(matricula)
        exists = doc_ref.get().exists

        if exists and not replace_existing:
            skipped += 1
            print(f"[SKIP] {matricula} ya existe")
            continue

        if dry_run:
            action = "UPDATE" if exists else "INSERT"
            print(f"[DRY-RUN][{action}] {matricula}")
            continue

        doc_ref.set(payload)
        if exists:
            updated += 1
            print(f"[OK][UPDATE] {matricula}")
        else:
            inserted += 1
            print(f"[OK][INSERT] {matricula}")

    print(
        "Finalizado "
        f"(inserted={inserted}, updated={updated}, skipped={skipped}, total={len(payloads)})"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Inserta vehículos de prueba en Firestore")
    parser.add_argument("--company-id", default=DEFAULT_COMPANY_ID, help="Company ID destino")
    parser.add_argument("--dry-run", action="store_true", help="No escribe en Firestore")
    parser.add_argument(
        "--replace-existing",
        action="store_true",
        help="Sobrescribe documentos existentes con la misma matrícula",
    )
    args = parser.parse_args()

    insertar_vehiculos(
        company_id=args.company_id,
        dry_run=args.dry_run,
        replace_existing=args.replace_existing,
    )


if __name__ == "__main__":
    main()

