from __future__ import annotations

import os
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth

from ..firebase_config import ensure_firebase_initialized, get_db

bearer_scheme = HTTPBearer(auto_error=False)
check_revoked = os.getenv("FIREBASE_CHECK_REVOKED", "false").lower() == "true"


async def get_current_user(
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict[str, Any]:

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Authorization header",
        )

    token = credentials.credentials.strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )

    try:
        ensure_firebase_initialized()
        return firebase_auth.verify_id_token(token, check_revoked=check_revoked)
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
        )
    except firebase_auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token revoked",
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )


async def get_current_encargado(
    current_user: dict[str, Any] = Depends(get_current_user)
) -> dict[str, Any]:
    uid = current_user.get("uid")

    db = get_db()
    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()

    if not user_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado en la base de datos"
        )

    user_data = user_doc.to_dict()
    rol = user_data.get("rol")

    # Verificación del rol (funciona si es String o si es Lista)
    if isinstance(rol, list):
        is_encargado = "encargado" in rol
    else:
        is_encargado = (rol == "encargado")

    if not is_encargado:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permisos de encargado para realizar esta acción"
        )

    # Opcional: Adjuntar los datos de firestore por si se necesitan en el endpoint
    current_user["rol"] = rol
    return current_user