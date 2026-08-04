from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException

from app.services import trans_service as trans_service_module
from app.services.trans_service import TransService


@pytest.fixture
def mock_user_crud():
    return MagicMock(name="UserCRUD")


@pytest.fixture
def service(mock_user_crud):
    return TransService(user_crud=mock_user_crud)


def test_delete_transportista_not_found_returns_404(service, mock_user_crud):
    mock_doc = MagicMock(exists=False)
    mock_user_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.delete_trans("u-missing", "comp-test")

    assert exc.value.status_code == 404


def test_delete_transportista_foreign_company_returns_404(service, mock_user_crud):
    mock_doc = MagicMock(exists=False)
    mock_user_crud.get_by_id.return_value = mock_doc

    with pytest.raises(HTTPException) as exc:
        service.delete_trans("u-foreign", "comp-test")

    assert exc.value.status_code == 404

def test_delete_transportista_returns_success_message(service, mock_user_crud, monkeypatch):
    mock_doc = MagicMock(exists=True)
    mock_doc.to_dict.return_value = {"companyId": "comp-test", "rol": ["transportista"]}
    mock_user_crud.get_by_id.return_value = mock_doc

    monkeypatch.setattr(trans_service_module.firebase_auth, "delete_user", lambda uid: None)

    result = service.delete_trans("u2", "comp-test")

    assert result["message"] == "Conductor eliminado con éxito"
