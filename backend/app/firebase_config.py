import os
from pathlib import Path
import firebase_admin
from firebase_admin import credentials
from google.cloud import firestore as g_firestore
from dotenv import load_dotenv

backend_dir = Path(__file__).resolve().parents[1]
load_dotenv(backend_dir / ".env")


def _resolve_credentials_path() -> str:
    raw_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
    if raw_path:
        candidate = Path(raw_path)
        if not candidate.is_absolute():
            candidate = backend_dir / candidate
        return str(candidate)

    default_candidates = [
        backend_dir / "gestion-transporte-dev-firebase-adminsdk-fbsvc-390f3bdf34.json",
        backend_dir / "firebase_credentials.json",
    ]
    for candidate in default_candidates:
        if candidate.exists():
            return str(candidate)

    # Mantener un valor final predecible para que el error sea claro.
    return str(backend_dir / "firebase_credentials.json")

_cred_path = _resolve_credentials_path()


def ensure_firebase_initialized() -> None:
    if firebase_admin._apps:
        return

    cred = credentials.Certificate(_cred_path)
    firebase_admin.initialize_app(cred)


def get_db():
    return g_firestore.Client(project=os.environ["GCLOUD_PROJECT"])


class _LazyFirestoreClient:
    def __getattr__(self, item):
        return getattr(get_db(), item)


# Mantiene compatibilidad con imports existentes (`from ..firebase_config import db`)
# sin inicializar Firebase en tiempo de import.
db = _LazyFirestoreClient()
