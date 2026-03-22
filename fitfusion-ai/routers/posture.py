# routers/posture.py
import os
from fastapi import APIRouter, File, UploadFile, Form
from fastapi.responses import JSONResponse
import mediapipe as mp
from mediapipe.tasks.python import BaseOptions
from mediapipe.tasks.python.vision import PoseLandmarker, PoseLandmarkerOptions
import cv2
import numpy as np

from analyzers.squat import analyze_squat
from analyzers.pushup import analyze_pushup
from analyzers.plank import analyze_plank

router = APIRouter()

SUPPORTED_EXERCISES = {
    "squat":  analyze_squat,
    "pushup": analyze_pushup,
    "plank":  analyze_plank
}

# Path to the downloaded pose landmarker model
MODEL_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "models", "pose_landmarker.task")

@router.post("/analyze")
async def analyze_posture(
    exercise: str = Form(...),
    image: UploadFile = File(...)
):
    # 1. Validate exercise type
    exercise = exercise.lower().strip()
    if exercise not in SUPPORTED_EXERCISES:
        return JSONResponse(
            status_code=400,
            content={
                "error": f"Unsupported exercise '{exercise}'",
                "supported": list(SUPPORTED_EXERCISES.keys())
            }
        )

    # 2. Read and decode image
    contents = await image.read()
    nparr = np.frombuffer(contents, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if frame is None:
        return JSONResponse(
            status_code=400,
            content={"error": "Could not read image. Please send a valid image file."}
        )

    # 3. Run MediaPipe PoseLandmarker (Tasks API)
    options = PoseLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=MODEL_PATH),
        num_poses=1,
    )

    with PoseLandmarker.create_from_options(options) as landmarker:
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        results = landmarker.detect(mp_image)

        # 4. Check if person detected
        if not results.pose_landmarks or len(results.pose_landmarks) == 0:
            return JSONResponse(
                status_code=200,
                content={
                    "detected": False,
                    "error": "No person detected. Make sure your full body is visible."
                }
            )

        landmarks = results.pose_landmarks[0]  # first detected person

        # 5. Run exercise-specific analyzer
        analyzer = SUPPORTED_EXERCISES[exercise]
        analysis = analyzer(landmarks)

        return {
            "detected": True,
            "exercise": exercise,
            "analysis": analysis
        }


@router.get("/exercises")
async def get_supported_exercises():
    return {
        "exercises": [
            {
                "id": "squat",
                "name": "Squat",
                "description": "Analyzes knee angle, back posture and symmetry",
                "keyPoints": ["Knee angle", "Back angle", "Leg symmetry"]
            },
            {
                "id": "pushup",
                "name": "Push Up",
                "description": "Analyzes elbow bend and body alignment",
                "keyPoints": ["Elbow angle", "Body alignment", "Hip position"]
            },
            {
                "id": "plank",
                "name": "Plank",
                "description": "Analyzes body straightness and hip position",
                "keyPoints": ["Body angle", "Hip level", "Neck position"]
            }
        ]
    }