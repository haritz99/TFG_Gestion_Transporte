from __future__ import annotations

import argparse
import random
from datetime import datetime, timezone
from typing import Any, Dict, List

from ..firebase_config import db
from ..schemas.users import UserSchema

DEFAULT_COMPANY_ID = "Oju2P1t0j6iBJ9llQGRK"

# Opciones para datos aleatorios
NOMBRES = ["Juan", "Maria", "Carlos", "Ana", "Pedro", "Lucia", "Diego", "Elena", "Jorge", "Sonia"]
APELLIDOS = ["García", "Rodríguez", "López", "Sánchez", "Martínez", "Pérez", "Gómez", "Ruiz", "Díaz", "Hernández"]
LICENCIAS_POSIBLES = ["C1", "C", "D1", "D", "BE", "C1E", "CE"]
ESTADOS = ["sin_asignar", "asignacion_parcial", "asignado", "inactivo"]

def _seed_usuarios(company_id: str) -> List[Dict[str, Any]]:
    """Genera 20 usuarios de prueba para Firestore."""
    usuarios = []
    
    # Aseguramos al menos un encargado extra (opcional)
    usuarios.append({
        "nombre": "Admin",
        "apellido": "De Prueba",
        "email": f"admin_test_{random.randint(100,999)}@example.com",
        "telefono": "600000000",
        "rol": ["encargado"],
        "permisosCond": [],
        "companyId": company_id,
        "estado": "sin_asignar",
        "createdAt": datetime.now(timezone.utc),
        "updatedAt": datetime.now(timezone.utc),
    })

    for i in range(1, 21):
        nombre = random.choice(NOMBRES)
        apellido = random.choice(APELLIDOS)
        email = f"{nombre.lower()}.{apellido.lower()}.{i}@example.com"
        
        # Simular algunos datos de transportista
        rol = ["transportista"]
        permisos = random.sample(LICENCIAS_POSIBLES, random.randint(1, 3))
        estado = random.choice(ESTADOS)
        
        usuario = {
            "nombre": nombre,
            "apellido": apellido,
            "email": email,
            "telefono": f"6{random.randint(10000000, 99999999)}",
            "rol": rol,
            "permisosCond": permisos,
            "companyId": company_id,
            "estado": estado,
            "vehiculoId": None if estado == "sin_asignar" else f"{random.randint(1000, 9999)}ABC",
            "cargaId": None if estado in ["sin_asignar", "inactivo"] else f"CARGA-{random.randint(100, 999)}",
            "createdAt": datetime.now(timezone.utc),
            "updatedAt": datetime.now(timezone.utc),
        }
        usuarios.append(usuario)
        
    return usuarios

def insertar_usuarios(company_id: str, dry_run: bool = False) -> None:
    usuarios_data = _seed_usuarios(company_id)
    users_ref = db.collection("users")

    inserted = 0
    errors = 0

    for data in usuarios_data:
        try:
            # Validamos con el Schema para asegurar que cumple los requisitos de Pydantic
            # Nota: El Schema pide uid opcional, pero al crear el doc en Firestore se autogenerará
            validated = UserSchema(**data)
            payload = validated.model_dump(exclude={"uid"})

            if dry_run:
                print(f"[DRY-RUN] Insertaría usuario: {data['email']}")
                continue

            # Usamos add() para que Firestore genere el ID automático (será el uid)
            doc_ref = users_ref.add(payload)
            # Actualizamos el documento con su propio ID para que el campo uid coincida
            doc_ref[1].update({"uid": doc_ref[1].id})
            
            inserted += 1
            print(f"[OK] Insertado: {data['email']} con ID: {doc_ref[1].id}")
            
        except Exception as e:
            errors += 1
            print(f"[ERROR] No se pudo insertar {data.get('email')}: {e}")

    print(f"\nFinalizado (inserted={inserted}, errors={errors}, total={len(usuarios_data)})")

def main() -> None:
    parser = argparse.ArgumentParser(description="Inserta usuarios de prueba en Firestore para gestión de equipo")
    parser.add_argument("--company-id", default=DEFAULT_COMPANY_ID, help="Company ID destino")
    parser.add_argument("--dry-run", action="store_true", help="No escribe en Firestore")
    args = parser.parse_args()

    insertar_usuarios(company_id=args.company_id, dry_run=args.dry_run)

if __name__ == "__main__":
    main()

