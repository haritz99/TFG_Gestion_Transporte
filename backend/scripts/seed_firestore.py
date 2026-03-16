import argparse
import json
import os
import sys
from typing import Any, Dict, List, Optional, Set, Tuple

from dotenv import load_dotenv

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except Exception:  # pragma: no cover - handled at runtime
    firebase_admin = None
    credentials = None
    firestore = None

COLLECTION_ORDER = [
    "users",
    "vehiculos",
    "cargas",
    "rutas",
    "incidencias",
    "tareas",
    "cartasDePorte",
]

REQUIRED_FIELDS = {
    "users": ["nombre", "apellidos", "email", "tfn", "rol"],
    "vehiculos": ["matricula", "marca", "modelo", "capacidad", "largo", "ancho", "alto", "interno", "disponible"],
    "cargas": ["peso", "largo", "ancho", "alto"],
    "rutas": ["origen", "destino"],
    "incidencias": ["descripcion", "fecha"],
    "tareas": ["fechaIni"],
    "cartasDePorte": [
        "transportistaId",
        "matVehi",
        "matRemol",
        "mercancia",
        "cantidad",
        "expedidor",
        "cargador",
        "destinatario",
        "fechaCarga",
    ],
}

ALLOWED_FIELDS = {
    "users": {
        "nombre",
        "apellidos",
        "email",
        "tfn",
        "rol",
        "permisosCond",
        "disponible",
    },
    "vehiculos": {
        "matricula",
        "marca",
        "modelo",
        "capacidad",
        "largo",
        "ancho",
        "alto",
        "disponible",
        "interno",
        "transportistaId",
    },
    "cargas": {
        "peso",
        "largo",
        "ancho",
        "alto",
        "tareaId",
        "rutaId",
    },
    "rutas": {
        "origen",
        "destino",
        "cargaId",
    },
    "incidencias": {
        "descripcion",
        "fecha",
        "transportistaId",
        "tareaId",
    },
    "tareas": {
        "fechaIni",
        "fechaFin",
        "encargadoId",
        "transportistaId",
    },
    "cartasDePorte": {
        "transportistaId",
        "matVehi",
        "matRemol",
        "mercancia",
        "cantidad",
        "expedidor",
        "cargador",
        "destinatario",
        "cargoRec",
        "nombreRec",
        "observaciones",
        "fechaCarga",
        "fechaEntrega",
        "encargadoId",
        "cargaId",
    },
}

VALID_ROLES = {"encargado", "transportista"}

# (field_name, target_collection, required)
REFERENCE_FIELDS = {
    "vehiculos": [("transportistaId", "users", False)],
    "cargas": [("tareaId", "tareas", False), ("rutaId", "rutas", False)],
    "rutas": [("cargaId", "cargas", False)],
    "incidencias": [("transportistaId", "users", True), ("tareaId", "tareas", False)],
    "tareas": [
        ("encargadoId", "users", False),
        ("transportistaId", "users", False),
    ],
    "cartasDePorte": [("cargaId", "cargas", True), ("transportistaId", "users", True)],
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Seeder idempotente para Firestore (modelo MER transporte)."
    )
    parser.add_argument(
        "--file",
        default=os.path.join(os.path.dirname(__file__), "seed_data_dev.example.json"),
        help="Ruta al JSON de seed.",
    )
    parser.add_argument(
        "--credentials",
        default=None,
        help="Ruta al service account JSON (si no se pasa, usa FIREBASE_CREDENTIALS_PATH).",
    )
    parser.add_argument(
        "--on-conflict",
        choices=["skip", "merge", "overwrite", "error"],
        default="skip",
        help="Que hacer si el documento ya existe.",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=400,
        help="Tamano de batch (max 500).",
    )
    parser.add_argument(
        "--collections",
        default="",
        help="Lista separada por comas de colecciones a procesar (ej: users,vehiculos).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="No escribe en Firestore, solo muestra el plan.",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Valida JSON y referencias internas sin conectar a Firestore.",
    )
    return parser.parse_args()


def load_seed_file(path: str) -> Dict[str, Dict[str, Dict[str, Any]]]:
    if not os.path.exists(path):
        raise FileNotFoundError("No existe el archivo de seed: {}".format(path))

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, dict):
        raise ValueError("El JSON raiz debe ser un objeto con colecciones.")

    normalized: Dict[str, Dict[str, Dict[str, Any]]] = {}
    for collection, docs in data.items():
        if not isinstance(docs, dict):
            raise ValueError("La coleccion '{}' debe ser un objeto id->doc".format(collection))

        normalized_docs: Dict[str, Dict[str, Any]] = {}
        for doc_id, payload in docs.items():
            if not isinstance(payload, dict):
                raise ValueError(
                    "Documento '{}.{}' debe ser un objeto".format(collection, doc_id)
                )
            normalized_docs[str(doc_id)] = payload
        normalized[collection] = normalized_docs

    return normalized


def filter_collections(
    data: Dict[str, Dict[str, Dict[str, Any]]],
    collection_filter: Set[str],
) -> Dict[str, Dict[str, Dict[str, Any]]]:
    if not collection_filter:
        return data
    return {k: v for k, v in data.items() if k in collection_filter}


def normalize_roles(data: Dict[str, Dict[str, Dict[str, Any]]]) -> None:
    users = data.get("users", {})
    for doc_id, doc in users.items():
        raw_role = str(doc.get("rol", "")).strip().lower()
        if raw_role:
            doc["rol"] = raw_role
        else:
            print("[WARN] users/{} sin rol definido".format(doc_id))


def validate_allowed_fields(data: Dict[str, Dict[str, Dict[str, Any]]]) -> List[str]:
    errors: List[str] = []

    for collection, docs in data.items():
        allowed = ALLOWED_FIELDS.get(collection)
        if allowed is None:
            continue

        for doc_id, doc in docs.items():
            for field_name in doc.keys():
                if field_name not in allowed:
                    errors.append(
                        "Campo no permitido '{}': {}/{}".format(field_name, collection, doc_id)
                    )

    return errors


def validate_required_fields(data: Dict[str, Dict[str, Dict[str, Any]]]) -> List[str]:
    errors: List[str] = []

    for collection, docs in data.items():
        required = REQUIRED_FIELDS.get(collection, [])
        for doc_id, doc in docs.items():
            for field in required:
                if field not in doc or doc[field] in (None, ""):
                    errors.append(
                        "Falta campo requerido '{}': {}/{}".format(field, collection, doc_id)
                    )

    for doc_id, doc in data.get("users", {}).items():
        role = doc.get("rol")
        if role not in VALID_ROLES:
            errors.append(
                "Rol invalido en users/{}: '{}' (validos: {})".format(
                    doc_id,
                    role,
                    ", ".join(sorted(VALID_ROLES)),
                )
            )

        if role == "transportista":
            for field in ("permisosCond", "disponible"):
                if field not in doc or doc[field] in (None, ""):
                    errors.append(
                        "Falta campo requerido '{}' para users/{} (rol transportista)".format(
                            field, doc_id
                        )
                    )

    return errors


def collect_seed_ids(data: Dict[str, Dict[str, Dict[str, Any]]]) -> Dict[str, Set[str]]:
    ids_by_collection: Dict[str, Set[str]] = {}
    for collection, docs in data.items():
        ids_by_collection[collection] = set(docs.keys())
    return ids_by_collection


def validate_references(
    data: Dict[str, Dict[str, Dict[str, Any]]],
    seed_ids: Dict[str, Set[str]],
    remote_existing_ids: Optional[Dict[str, Set[str]]] = None,
) -> List[str]:
    errors: List[str] = []
    remote_existing_ids = remote_existing_ids or {}

    for collection, docs in data.items():
        refs = REFERENCE_FIELDS.get(collection, [])
        for doc_id, doc in docs.items():
            for field_name, target_collection, required in refs:
                value = doc.get(field_name)
                if value in (None, ""):
                    if required:
                        errors.append(
                            "Referencia requerida faltante '{}': {}/{}".format(
                                field_name, collection, doc_id
                            )
                        )
                    continue

                value = str(value)
                in_seed = value in seed_ids.get(target_collection, set())
                in_remote = value in remote_existing_ids.get(target_collection, set())

                if not in_seed and not in_remote:
                    errors.append(
                        "Referencia no encontrada {}='{}' en {}/{} -> {}".format(
                            field_name,
                            value,
                            collection,
                            doc_id,
                            target_collection,
                        )
                    )

    return errors


def init_firestore(credential_path: Optional[str]):
    if firebase_admin is None or credentials is None:
        raise RuntimeError(
            "Falta dependencia firebase-admin. Ejecuta: pip install firebase-admin"
        )

    load_dotenv()

    cred_path = credential_path or os.getenv(
        "FIREBASE_CREDENTIALS_PATH", "firebase_credentials.json"
    )

    if not os.path.exists(cred_path):
        raise FileNotFoundError(
            "No se encontro el service account JSON en '{}'".format(cred_path)
        )

    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

    return firestore.client()


def fetch_existing_ids(
    db,
    ids_by_collection: Dict[str, Set[str]],
) -> Dict[str, Set[str]]:
    existing: Dict[str, Set[str]] = {k: set() for k in ids_by_collection.keys()}

    for collection, ids in ids_by_collection.items():
        if not ids:
            continue

        refs = [db.collection(collection).document(doc_id) for doc_id in ids]
        snapshots = db.get_all(refs)
        for snap in snapshots:
            if snap.exists:
                existing[collection].add(snap.id)

    return existing


def build_write_plan(
    data: Dict[str, Dict[str, Dict[str, Any]]],
    existing_ids: Dict[str, Set[str]],
    on_conflict: str,
) -> Tuple[List[Tuple[str, str, Dict[str, Any], bool]], Dict[str, int]]:
    """
    Returns:
    - list of writes: (collection, doc_id, data, merge)
    - counters dict
    """
    writes: List[Tuple[str, str, Dict[str, Any], bool]] = []
    counters = {
        "create": 0,
        "update": 0,
        "skip": 0,
        "error": 0,
    }

    ordered_collections = [c for c in COLLECTION_ORDER if c in data]
    for collection in data.keys():
        if collection not in ordered_collections:
            ordered_collections.append(collection)

    for collection in ordered_collections:
        docs = data[collection]
        existing = existing_ids.get(collection, set())

        for doc_id, payload in docs.items():
            already_exists = doc_id in existing

            if not already_exists:
                writes.append((collection, doc_id, payload, False))
                counters["create"] += 1
                continue

            if on_conflict == "skip":
                counters["skip"] += 1
                continue

            if on_conflict == "error":
                counters["error"] += 1
                continue

            if on_conflict == "merge":
                writes.append((collection, doc_id, payload, True))
                counters["update"] += 1
                continue

            # overwrite
            writes.append((collection, doc_id, payload, False))
            counters["update"] += 1

    return writes, counters


def commit_writes(db, writes: List[Tuple[str, str, Dict[str, Any], bool]], batch_size: int) -> None:
    if batch_size <= 0 or batch_size > 500:
        raise ValueError("--batch-size debe estar entre 1 y 500")

    batch = db.batch()
    pending = 0
    committed = 0

    for collection, doc_id, payload, merge in writes:
        ref = db.collection(collection).document(doc_id)
        batch.set(ref, payload, merge=merge)
        pending += 1

        if pending == batch_size:
            batch.commit()
            committed += pending
            print("[INFO] Batch commit: {} escrituras".format(pending))
            batch = db.batch()
            pending = 0

    if pending > 0:
        batch.commit()
        committed += pending
        print("[INFO] Batch commit final: {} escrituras".format(pending))

    print("[OK] Escrituras totales aplicadas: {}".format(committed))


def print_summary(counters: Dict[str, int], writes_len: int, dry_run: bool) -> None:
    mode = "DRY RUN" if dry_run else "APLICADO"
    print("\n===== RESUMEN ({}) =====".format(mode))
    print("A crear: {}".format(counters["create"]))
    print("A actualizar: {}".format(counters["update"]))
    print("Saltados: {}".format(counters["skip"]))
    print("Conflictos (error): {}".format(counters["error"]))
    print("Total writes planificadas: {}".format(writes_len))


def main() -> int:
    args = parse_args()

    requested_collections = {
        c.strip() for c in args.collections.split(",") if c.strip()
    }

    try:
        data = load_seed_file(args.file)
        data = filter_collections(data, requested_collections)
        normalize_roles(data)

        allowed_field_errors = validate_allowed_fields(data)
        if allowed_field_errors:
            print("\n[ERROR] Hay campos no definidos en el MER:")
            for err in allowed_field_errors:
                print(" - {}".format(err))
            return 1

        required_errors = validate_required_fields(data)
        if required_errors:
            print("\n[ERROR] Validacion de campos fallida:")
            for err in required_errors:
                print(" - {}".format(err))
            return 1

        seed_ids = collect_seed_ids(data)

        if args.validate_only:
            ref_errors = validate_references(data, seed_ids)
            if ref_errors:
                print("\n[ERROR] Validacion de referencias internas fallida:")
                for err in ref_errors:
                    print(" - {}".format(err))
                return 1

            print("[OK] Validacion local completada. Sin conexion a Firestore.")
            return 0

        db = init_firestore(args.credentials)

        existing_ids = fetch_existing_ids(db, seed_ids)
        ref_errors = validate_references(data, seed_ids, remote_existing_ids=existing_ids)
        if ref_errors:
            print("\n[ERROR] Validacion de referencias fallida:")
            for err in ref_errors:
                print(" - {}".format(err))
            return 1

        writes, counters = build_write_plan(data, existing_ids, args.on_conflict)

        if counters["error"] > 0:
            print(
                "[ERROR] Hay documentos existentes y --on-conflict=error. "
                "No se ha escrito nada."
            )
            print_summary(counters, len(writes), dry_run=True)
            return 1

        print_summary(counters, len(writes), dry_run=args.dry_run)

        if args.dry_run:
            return 0

        if not writes:
            print("[OK] No hay cambios para aplicar.")
            return 0

        commit_writes(db, writes, batch_size=args.batch_size)
        return 0

    except Exception as exc:
        print("[FATAL] {}".format(exc))
        return 1


if __name__ == "__main__":
    sys.exit(main())

