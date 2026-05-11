from __future__ import annotations

import argparse
import random
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List

from ..firebase_config import db
from ..schemas.pedido import EstadoPedido
from ..schemas.carga import EstadoCarga

DEFAULT_COMPANY_ID = "Oju2P1t0j6iBJ9llQGRK"
CLIENTE_ID = "EbmliX5MxPgRYKE4smXD"

ORIGENES = ["Madrid", "Barcelona", "Valencia", "Zaragoza", "Sevilla"]
DESTINOS = ["Bilbao", "Málaga", "Alicante", "Valladolid", "Vigo"]
MERCANCIAS = ["Palets de madera", "Ropa", "Electrónica", "Materiales", "Alimentos", "Automóviles"]
CONDUCTORES = ["Juan García", "María López", "Carlos Ruiz", "Elena Sanz", "Pedro Gómez"]
VEHICULOS = ["1234-BBB", "5678-CCC", "9012-DDD", "3456-FFF", "7890-GGG"]

def _crear_pedido(company_id: str, suffix: int) -> Dict[str, Any]:
    now = datetime.now(timezone.utc)
    start = now + timedelta(days=random.randint(0, 2))
    end = start + timedelta(days=random.randint(5, 10))

    return {
        "descripcion": f"Pedido de prueba {suffix}",
        "fechaCarga": start,
        "fechaDescarga": end,
        "origenes": ORIGENES,
        "destinos": DESTINOS,
        "estado": EstadoPedido.PLANIFICADO.value,
        "clienteId": CLIENTE_ID,
        "companyId": company_id,
        "createdAt": now,
        "updatedAt": now,
    }

def _crear_carga_para_pedido(company_id: str, pedido_id: str, pedido_data: Dict[str, Any]) -> Dict[str, Any]:
    now = datetime.now(timezone.utc)

    # Las fechas de la carga deben estar dentro de las fechas del pedido
    p_start = pedido_data["fechaCarga"]
    p_end = pedido_data["fechaDescarga"]

    # Forzamos que muchas cargas caigan el mismo día para probar el calendario
    # day_offset = 0 (mismo día del pedido), day_offset = 1 (al día siguiente)
    day_offset = random.choice([0, 0, 0, 1])

    # Asignamos horas aleatorias entre las 8:00 y las 16:00
    c_start = p_start + timedelta(days=day_offset, hours=random.randint(8, 16))
    if c_start >= p_end:
        c_start = p_start

    # Duración de la carga (entre 4 y 12 horas)
    c_end = c_start + timedelta(hours=random.randint(4, 12))
    if c_end > p_end:
        c_end = p_end

    return {
        "origen": random.choice(pedido_data["origenes"]),
        "destino": random.choice(pedido_data["destinos"]),
        "mercancia": random.choice(MERCANCIAS),
        "numBultos": random.randint(10, 100),
        "peso": round(random.uniform(100.0, 5000.0), 2),
        "precio": 100,
        "largo": round(random.uniform(1.0, 5.0), 2),
        "ancho": round(random.uniform(1.0, 2.5), 2),
        "alto": round(random.uniform(1.0, 3.0), 2),
        "estado": EstadoCarga.PENDIENTE.value,
        "fechaCarga": c_start,
        "fechaDescarga": c_end,
        "pedidoId": pedido_id,
        "companyId": company_id,
        "clienteId": pedido_data["clienteId"],
        "createdAt": now,
        "updatedAt": now,
    }

def _crear_datos_mayo_junio(company_id: str) -> List[Dict[str, Any]]:
    cargas = []
    # Generar cargas para Mayo y Junio 2026
    start_date = datetime(2026, 5, 1, tzinfo=timezone.utc)

    for day in range(60): # 60 días para cubrir Mayo y parte de Junio
        actual_day = start_date + timedelta(days=day)

        # Probabilidad de tener cargas ese día
        num_cargas = random.choices([0, 1, 2, 3, 4], weights=[5, 30, 40, 20, 5])[0]

        for i in range(num_cargas):
            # Determinamos el estado aleatoriamente
            estado = random.choice(list(EstadoCarga))

            # Para cumplir con las validaciones de CargaSchema:
            # 1. Si el estado NO es PENDIENTE, DEBE tener transportista O vehículo.
            # 2. Si el estado ES PENDIENTE, NO PUEDE tener ni transportista NI vehículo.

            conductor = None
            vehiculo = None

            if estado != EstadoCarga.PENDIENTE:
                # Asignamos obligatoriamente para cumplir validación
                conductor = random.choice(CONDUCTORES)
                vehiculo = random.choice(VEHICULOS)
            else:
                # Forzamos que sean None para cumplir validación de 'pendiente'
                conductor = None
                vehiculo = None

            # Horas aleatorias entre las 06:00 y las 20:00
            hora_inicio = random.randint(6, 18)
            duracion = random.randint(2, 10)

            fecha_carga = actual_day.replace(hour=hora_inicio, minute=random.choice([0, 15, 30, 45]))
            fecha_descarga = fecha_carga + timedelta(hours=duracion)

            carga = {
                "origen": random.choice(ORIGENES),
                "destino": random.choice(DESTINOS),
                "mercancia": random.choice(MERCANCIAS),
                "numBultos": random.randint(5, 50),
                "peso": round(random.uniform(500, 10000), 2),
                "precio": 100,
                "largo": round(random.uniform(1.0, 13.6), 1),
                "ancho": 2.4,
                "alto": 2.6,
                "estado": estado.value,
                "fechaCarga": fecha_carga,
                "fechaDescarga": fecha_descarga,
                "pedidoId": f"PED-{random.randint(1, 100):03d}",
                "companyId": company_id,
                "clienteId": CLIENTE_ID,
                "transportistaId": conductor,
                "vehiculoId": vehiculo,
                "createdAt": datetime.now(timezone.utc),
                "updatedAt": datetime.now(timezone.utc),
            }
            cargas.append(carga)

    return cargas

def insertar_datos(company_id: str, dry_run: bool = False) -> None:
    cargas_ref = db.collection("cargas")

    # 1. Limpiar cargas existentes de esta compañía
    print(f"--- Limpiando cargas existentes para {company_id} ---")
    docs = cargas_ref.where("companyId", "==", company_id).stream()
    count_deleted = 0
    for doc in docs:
        if not dry_run:
            doc.reference.delete()
        count_deleted += 1
    print(f"Eliminadas {count_deleted} cargas.")

    # 2. Insertar nuevas cargas masivas para Mayo/Junio 2026
    print(f"--- Generando e insertando nuevas cargas ---")
    nuevas_cargas = _crear_datos_mayo_junio(company_id)

    count_inserted = 0
    for i, carga_data in enumerate(nuevas_cargas):
        new_id = f"CRG-TEST-{i+1:03d}"
        if not dry_run:
            cargas_ref.document(new_id).set(carga_data)
        count_inserted += 1
        if i % 20 == 0:
            print(f"Progreso: {count_inserted}/{len(nuevas_cargas)}...")

    print(f"\nFinalizado: {count_inserted} cargas creadas (Dry-run: {dry_run})")

def main() -> None:
    parser = argparse.ArgumentParser(description="Limpia e inserta cargas de prueba para Mayo/Junio 2026")
    parser.add_argument("--company-id", default=DEFAULT_COMPANY_ID, help="Company ID destino")
    parser.add_argument("--dry-run", action="store_true", help="No escribe en Firestore")
    args = parser.parse_args()

    insertar_datos(company_id=args.company_id, dry_run=args.dry_run)

if __name__ == "__main__":
    main()
