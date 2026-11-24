"""Stub analysis backend. Run: uvicorn main:app --host 0.0.0.0 --port 8000

Returns the same JSON shape the iOS app expects (SwingAnalysis in SwingRecord.swift).
Replace the TODO with the real pipeline: pose -> swing phases -> metrics -> feedback.
"""
import json
import random
import tempfile

from fastapi import FastAPI, File, Form, UploadFile

app = FastAPI()


@app.post("/analyze")
async def analyze(video: UploadFile = File(...), profile: str | None = Form(None)):
    body = json.loads(profile) if profile else {}

    with tempfile.NamedTemporaryFile(suffix=".mov", delete=False) as f:
        f.write(await video.read())
        video_path = f.name

    # TODO: run MediaPipe on video_path, detect swing phases, compute metrics,
    # and compare them to targets derived from `body` (the golfer's profile).
    shoulder_turn = random.uniform(60, 100)
    target = min(body.get("trunkRotationDegrees") or 90, 90)

    faults = []
    if shoulder_turn < target - 10:
        faults.append({
            "title": "Incomplete shoulder turn",
            "detail": f"You turned {shoulder_turn:.0f} degrees; your screen shows about {target:.0f}.",
        })

    return {
        "tempoRatio": round(random.uniform(2.4, 3.6), 2),
        "metrics": [
            {"name": "Shoulder turn", "value": shoulder_turn, "unit": "°"},
            {"name": "Hip turn", "value": random.uniform(30, 55), "unit": "°"},
        ],
        "faults": faults,
        "isMock": True,
    }
