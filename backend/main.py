
import os
import tempfile

from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field

from local_tts.inference import generate_speech

app = FastAPI(
    title="Text-to-Speech API",
    description="Local FastSpeech 2 and HiFi-GAN API",
    version="2.0.0"
)


class SpeechRequest(BaseModel):
    text: str = Field(min_length=1)
    pitch_control: float = 1.0
    energy_control: float = 1.0
    duration_control: float = 1.0


@app.get("/")
def home():
    return {
        "message": "Welcome to the Local Text-to-Speech API!",
        "status": "Backend is running successfully"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "model": "FastSpeech 2 + HiFi-GAN",
        "execution": "local"
    }


@app.post("/synthesize")
def synthesize_speech(request: SpeechRequest):
    if not request.text.strip():
        raise HTTPException(
            status_code=400,
            detail="Input text cannot be empty."
        )

    output_path = None

    try:
        with tempfile.NamedTemporaryFile(
            suffix=".wav",
            delete=False
        ) as temp_file:
            output_path = temp_file.name

        generate_speech(request.text, output_path)

        with open(output_path, "rb") as audio_file:
            audio_data = audio_file.read()

        return Response(
            content=audio_data,
            media_type="audio/wav",
            headers={
                "Content-Disposition": "attachment; filename=speech.wav"
            }
        )

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Local speech generation failed: {str(error)}"
        )

    finally:
        if output_path and os.path.exists(output_path):
            os.remove(output_path)
