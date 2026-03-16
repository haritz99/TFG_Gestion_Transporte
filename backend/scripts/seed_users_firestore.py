import argparse
import json
import os
import re
import sys
from typing import Any, Dict, List, Optional, Tuple

from dotenv import load_dotenv

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except Exception:  # pragma: no cover - handled at runtime
    firebase_admin = None
    credentials = None
    firestore = None

VALID_ROLES = {"encargado", "transportista"}

ALLOWED_FIELDS = {
    "nombre",
    "apellidos",
    "email",
    "tfn",
    "tfno",
    "roles",
    "permisosConduccion",
    "disponible",
    "vehiculoId",
}


EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Seeder de users para Firestore con IDs autogenerados."
    )
    parser.add_argument(
        "--file",
        default=os.path.join(os.path.dirname(__file__), "seed_users.example.json"),
        help="Ruta al JSON de users.",
    )
    parser.add_argument(
        "--credentials",
        default=None,
        help="Ruta al service account JSON (si no se pasa, usa FIREBASE_CREDENTIALS_PATH).",
    )
    parser.add_argument(
        "--on-conflict",
        choices=["skip", "merge", "error"],
        default="skip",
        help="Que hacer si ya existe un user con el mismo email.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="No escribe en Firestore, solo muestra el plan.",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Valida JSON sin conectar a Firestore.",
    )
    return parser.parse_args()


def load_seed_users(path: str) -> List[Dict[str, Any]]:
    if not os.path.exists(path):
        raise FileNotFoundError("No existe el archivo de seed: {}".format(path))

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, dict) or "users" not in data:
        raise ValueError("El JSON raiz debe tener una clave 'users'.")

    users = data["users"]
    if not isinstance(users, list):
        raise ValueError("'users' debe ser un array de objetos.")

    for idx, user in enumerate(users):
        if not isinstance(user, dict):
            raise ValueError("users[{}] debe ser un objeto".format(idx))

    return users


def normalize_user(user: Dict[str, Any]) -> Dict[str, Any]:
    normalized = dict(user)

    if "tfno" in normalized and "tfn" not in normalized:
        normalized["tfn"] = normalized.pop("tfno")

    raw_roles = normalized.get("roles", [])
    if isinstance(raw_roles, str):
        raw_roles = [raw_roles]

    roles: List[str] = []
    if isinstance(raw_roles, list):
        for role in raw_roles:
            value = str(role).strip().lower()
            if value:
                roles.append(value)

    normalized["roles"] = sorted(set(roles))

    if "email" in normalized:
        normalized["email"] = str(normalized["email"]).strip().lower()

    for key in ("nombre", "apellidos", "tfn", "vehiculoId"):
        if key in normalized and normalized[key] is not None:
            normalized[key] = str(normalized[key]).strip()

    return normalized


def validate_users(users: List[Dict[str, Any]]) -> List[str]:
    errors: List[str] = []
    seen_emails = set()

    for idx, user in enumerate(users):
        tag = "users[{}]".format(idx)

        unknown_fields = [k for k in user.keys() if k not in ALLOWED_FIELDS]
        for field_name in unknown_fields:
            errors.append("Campo no permitido '{}' en {}".format(field_name, tag))

        for required in ("nombre", "apellidos", "email", "tfn", "roles"):
            if required not in user or user[required] in (None, ""):
                errors.append("Falta campo requerido '{}' en {}".format(required, tag))

        email = str(user.get("email", "")).strip().lower()
        if not EMAIL_RE.match(email):
            errors.append("Email invalido en {}: '{}'".format(tag, user.get("email")))
        elif email in seen_emails:
            errors.append("Email duplicado en el JSON: '{}'".format(email))
        else:
            seen_emails.add(email)

        roles = user.get("roles", [])
        if not isinstance(roles, list) or not roles:
            errors.append("'roles' debe ser un array no vacio en {}".format(tag))
            continue

        invalid_roles = [r for r in roles if r not in VALID_ROLES]
        if invalid_roles:
            errors.append(
                "Roles invalidos en {}: {} (validos: {})".format(
                    tag,
                    ", ".join(invalid_roles),
                    ", ".join(sorted(VALID_ROLES)),
                )
            )

        is_transportista = "transportista" in roles
        if is_transportista:
            permisos = user.get("permisosConduccion")
            if not isinstance(permisos, list) or not permisos:
                errors.append(
                    "Falta 'permisosConduccion' (array no vacio) en {} para rol transportista".format(
                        tag
                    )
                )

            if not isinstance(user.get("disponible"), bool):
                errors.append(
                    "Falta 'disponible' (bool) en {} para rol transportista".format(tag)
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


def find_user_by_email(db, email: str):
    docs = list(db.collection("users").where("email", "==", email).limit(1).stream())
    return docs[0] if docs else None


def apply_seed(
    db,
    users: List[Dict[str, Any]],
    on_conflict: str,
    dry_run: bool,
) -> Tuple[int, int, int]:
    created = 0
    updated = 0
    skipped = 0

    for user in users:
        email = user["email"]
        existing = find_user_by_email(db, email)

        if existing is not None:
            if on_conflict == "skip":
                skipped += 1
                print("[SKIP] users/{} (email={})".format(existing.id, email))
                continue

            if on_conflict == "error":
                raise RuntimeError(
                    "Conflicto: ya existe users/{} con email '{}'".format(existing.id, email)
                )

            if dry_run:
                updated += 1
                print("[DRY] merge users/{} (email={})".format(existing.id, email))
            else:
                db.collection("users").document(existing.id).set(user, merge=True)
                updated += 1
                print("[OK] merge users/{} (email={})".format(existing.id, email))
            continue

        if dry_run:
            created += 1
            print("[DRY] create users/<auto-id> (email={})".format(email))
        else:
            doc_ref = db.collection("users").document()
            doc_ref.set(user)
            created += 1
            print("[OK] create users/{} (email={})".format(doc_ref.id, email))

    return created, updated, skipped


def main() -> int:
    args = parse_args()

    try:
        users = load_seed_users(args.file)
        normalized_users = [normalize_user(u) for u in users]

        validation_errors = validate_users(normalized_users)
        if validation_errors:
            print("\n[ERROR] Validacion fallida:")
            for err in validation_errors:
                print(" - {}".format(err))
            return 1

        if args.validate_only:
            print("[OK] Validacion local completada. Usuarios validos: {}".format(len(normalized_users)))
            return 0

        db = init_firestore(args.credentials)

        created, updated, skipped = apply_seed(
            db=db,
            users=normalized_users,
            on_conflict=args.on_conflict,
            dry_run=args.dry_run,
        )

        mode = "DRY RUN" if args.dry_run else "APLICADO"
        print("\n===== RESUMEN ({}) =====".format(mode))
        print("Creados: {}".format(created))
        print("Actualizados: {}".format(updated))
        print("Saltados: {}".format(skipped))
        print("Total procesados: {}".format(len(normalized_users)))
        return 0

    except Exception as exc:
        print("[FATAL] {}".format(exc))
        return 1


if __name__ == "__main__":
    sys.exit(main())

