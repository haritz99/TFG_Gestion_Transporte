from fastapi import FastAPI
from fastapi.testclient import TestClient

from backend.app.dependencies.auth import get_current_encargado
from backend.app.routers import trans


class FakeUserNotFoundError(Exception):
    pass


class FakeFirebaseAuth:
    UserNotFoundError = FakeUserNotFoundError

    def __init__(self, *, user_exists: bool = True):
        self.user_exists = user_exists
        self.deleted_uids: list[str] = []

    def delete_user(self, uid: str) -> None:
        if not self.user_exists:
            raise FakeUserNotFoundError("not found")
        self.deleted_uids.append(uid)


class FakeDocSnapshot:
    def __init__(self, exists: bool, data: dict | None = None, doc_id: str | None = None):
        self.exists = exists
        self._data = data or {}
        self.id = doc_id

    def to_dict(self):
        return dict(self._data)


class FakeDocRef:
    def __init__(self, collection_store: dict[str, dict], doc_id: str):
        self._collection_store = collection_store
        self._doc_id = doc_id

    def get(self):
        data = self._collection_store.get(self._doc_id)
        if data is None:
            return FakeDocSnapshot(False, doc_id=self._doc_id)
        return FakeDocSnapshot(True, data=data, doc_id=self._doc_id)

    def update(self, payload: dict):
        if self._doc_id not in self._collection_store:
            raise KeyError(self._doc_id)
        self._collection_store[self._doc_id].update(payload)

    def delete(self):
        self._collection_store.pop(self._doc_id, None)


class FakeCollection:
    def __init__(self, collection_store: dict[str, dict]):
        self._collection_store = collection_store

    def document(self, doc_id: str):
        return FakeDocRef(self._collection_store, doc_id)


class FakeDB:
    def __init__(self, users: dict[str, dict] | None = None):
        self._store = {"users": users or {}}

    def collection(self, name: str):
        return FakeCollection(self._store.setdefault(name, {}))


def _build_client(monkeypatch, users: dict[str, dict], *, auth_user_exists: bool = True):
    app = FastAPI()
    app.include_router(trans.router)
    app.dependency_overrides[get_current_encargado] = lambda: {"uid": "encargado-test"}

    fake_db = FakeDB(users=users)
    fake_auth = FakeFirebaseAuth(user_exists=auth_user_exists)

    monkeypatch.setattr(trans, "db", fake_db)
    monkeypatch.setattr(trans, "firebase_auth", fake_auth)

    return TestClient(app), fake_db, fake_auth


def test_delete_transportista_not_found_returns_404(monkeypatch):
    client, _, _ = _build_client(monkeypatch, users={})

    response = client.delete("/trans/missing")

    assert response.status_code == 404
    assert response.json()["detail"] == "Transportista no encontrado"


def test_delete_user_without_transportista_role_returns_400(monkeypatch):
    users = {
        "u1": {
            "rol": ["encargado"],
            "vehiculoId": None,
        }
    }
    client, _, _ = _build_client(monkeypatch, users=users)

    response = client.delete("/trans/u1")

    assert response.status_code == 400
    assert response.json()["detail"] == "El usuario indicado no es transportista"


def test_delete_transportista_with_vehicle_returns_vehicle_released_message(monkeypatch):
    users = {
        "u2": {
            "rol": ["transportista"],
            "vehiculoId": "veh-123",
        }
    }
    client, db, auth = _build_client(monkeypatch, users=users)

    response = client.delete("/trans/u2")

    assert response.status_code == 200
    assert response.json()["message"] == "Transportista eliminado con éxito y vehículo liberado"
    assert "u2" not in db._store["users"]
    assert auth.deleted_uids == ["u2"]


def test_delete_transportista_without_vehicle_returns_success_message(monkeypatch):
    users = {
        "u3": {
            "rol": ["transportista"],
            "vehiculoId": None,
        }
    }
    client, db, auth = _build_client(monkeypatch, users=users)

    response = client.delete("/trans/u3")

    assert response.status_code == 200
    assert response.json()["message"] == "Transportista eliminado con éxito"
    assert "u3" not in db._store["users"]
    assert auth.deleted_uids == ["u3"]


def test_delete_transportista_when_auth_user_missing_still_deletes_firestore(monkeypatch):
    users = {
        "u4": {
            "rol": ["transportista"],
            "vehiculoId": None,
        }
    }
    client, db, auth = _build_client(monkeypatch, users=users, auth_user_exists=False)

    response = client.delete("/trans/u4")

    assert response.status_code == 200
    assert response.json()["message"] == "Transportista eliminado con éxito"
    assert "u4" not in db._store["users"]
    assert auth.deleted_uids == []

