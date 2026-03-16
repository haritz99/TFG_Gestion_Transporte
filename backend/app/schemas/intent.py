from pydantic import BaseModel


class IntentRequest(BaseModel):
    text: str
    user_id: str


class IntentResponse(BaseModel):
    intent: str
    entities: dict
    response: str
