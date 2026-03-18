from fastapi import APIRouter, Depends, HTTPException

from ..dependencies.auth import get_current_user
from ..schemas.intent import IntentRequest, IntentResponse
from ..services.groq_service import detect_intent

router = APIRouter(
    prefix="/intent",
    tags=["intent"],
    dependencies=[Depends(get_current_user)],
)


@router.post("/", response_model=IntentResponse)
async def process_intent(request: IntentRequest):
    try:
        result = detect_intent(request.text)
        return IntentResponse(
            intent=result.get("intent", "desconocido"),
            entities=result.get("entities", {}),
            response=result.get("response", "No he podido procesar tu solicitud."),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
