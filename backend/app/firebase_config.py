import os
from pathlib import Path
import firebase_admin
from firebase_admin import credentials, firestore
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

if not firebase_admin._apps:
    cred = credentials.Certificate(_cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()
