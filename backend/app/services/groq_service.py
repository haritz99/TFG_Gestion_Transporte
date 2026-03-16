import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

SYSTEM_PROMPT = """Eres un asistente para una aplicación de gestión de transporte profesional.
Tu trabajo es clasificar la intención del usuario a partir de su mensaje de voz transcrito.

Debes responder SOLO con un JSON con los campos:
- "intent": la intención detectada (una de: consultar_cargas, siguiente_entrega, confirmar_recogida, confirmar_entrega, reportar_incidencia, consultar_kilometros, desconocido)
- "entities": un objeto con las entidades extraídas del texto (origen, destino, descripcion, etc.)
- "response": una respuesta breve en español para el usuario

Ejemplo de respuesta:
{"intent": "consultar_cargas", "entities": {}, "response": "Tienes 3 cargas asignadas para hoy."}
"""


def detect_intent(text: str) -> dict:
    chat_completion = client.chat.completions.create(
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        model="llama-3.1-8b-instant",
        temperature=0.1,
        response_format={"type": "json_object"},
    )

    import json
    response_text = chat_completion.choices[0].message.content
    return json.loads(response_text)
