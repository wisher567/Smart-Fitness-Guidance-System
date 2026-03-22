# routers/realtime.py
# Real-time frame-by-frame posture analysis
# Flutter app sends camera frames every 500ms as base64 images
import time
import base64

import cv2
import numpy as np
import mediapipe as mp
from fastapi import APIRouter
from pydantic import BaseModel

from analyzers.squat import analyze_squat
from analyzers.pushup import analyze_pushup
from analyzers.plank import analyze_plank

router = APIRouter()

SUPPORTED_EXERCISES = {
    "squat":  analyze_squat,
    "pushup": analyze_pushup,
    "plank":  analyze_plank,
}


class FrameRequest(BaseModel):
    image: str       # base64-encoded JPEG/PNG frame from Flutter camera
    exercise: str    # "squat" | "pushup" | "plank"
    timestamp: float # Unix timestamp (ms) from Flutter


@router.post("/frame")
async def analyze_frame(request: FrameRequest):
    """
    Analyze a single camera frame for posture detection.
    Called by Flutter every 500ms during live workout.
    Returns instant feedback — no database writes.
    """
    try:
        # ── 1. Validate exercise ──────────────────────────────────────────────
        exercise = request.exercise.lower().strip()
        if exercise not in SUPPORTED_EXERCISES:
            return {
                "detected": False,
                "error": f"Unsupported exercise. Choose: {list(SUPPORTED_EXERCISES.keys())}",
            }

        # ── 2. Decode base64 image ────────────────────────────────────────────
        try:
            image_data = request.image
            # Strip data-URL prefix if present: "data:image/jpeg;base64,/9j/..."
            if "," in image_data:
                image_data = image_data.split(",", 1)[1]

            image_bytes = base64.b64decode(image_data)
            nparr = np.frombuffer(image_bytes, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        except Exception as e:
            return {"detected": False, "error": f"Invalid image data: {e}"}

        if frame is None:
            return {"detected": False, "error": "Could not decode image frame"}

        # ── 3. Resize for faster processing (max 480px on longest side) ───────
        h, w = frame.shape[:2]
        max_size = 480
        if w > max_size or h > max_size:
            scale = max_size / max(w, h)
            frame = cv2.resize(frame, (int(w * scale), int(h * scale)))

        # ── 4. Run MediaPipe Pose (Solutions API, optimised for video) ─────────
        start_time = time.time()
        mp_pose = mp.solutions.pose   # access lazily per request (avoids module-init crash)
        with mp_pose.Pose(
            static_image_mode=False,   # treat as video stream → faster
            model_complexity=0,        # 0 = lite model, lowest latency
            smooth_landmarks=True,     # smooth jitter between frames
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        ) as pose:
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb_frame)

        processing_ms = round((time.time() - start_time) * 1000)

        # ── 5. Person detection check ─────────────────────────────────────────
        if not results.pose_landmarks:
            return {
                "detected": False,
                "exercise": exercise,
                "message": "No person detected. Make sure your full body is visible.",
                "processingTimeMs": processing_ms,
            }

        landmarks = results.pose_landmarks.landmark

        # ── 6. Extract key landmark coords for skeleton overlay ───────────────
        key_landmarks = _extract_key_landmarks(landmarks)

        # ── 7. Run exercise-specific analyzer ─────────────────────────────────
        # The analyzers expect a list-like object of landmark objects
        analysis = SUPPORTED_EXERCISES[exercise](landmarks)

        # ── 8. Build compact real-time response ───────────────────────────────
        return {
            "detected": True,
            "exercise": exercise,
            "score": analysis.get("score", 0),
            "grade": analysis.get("grade", "?"),
            "feedback": analysis.get("feedback", []),
            "angles": analysis.get("angles", {}),
            "recommendation": analysis.get("recommendation", ""),
            "keyLandmarks": key_landmarks,
            "repCount": None,          # future feature: rep counting
            "processingTimeMs": processing_ms,
            "timestamp": request.timestamp,
        }

    except Exception as e:
        return {
            "detected": False,
            "error": f"Analysis error: {e}",
            "processingTimeMs": 0,
        }


def _extract_key_landmarks(landmarks) -> dict:
    """
    Return normalised x/y coords (0-1) for key body joints.
    Flutter maps these to screen pixels to draw the skeleton overlay.
    """
    def lm(idx: int) -> dict:
        p = landmarks[idx]
        return {
            "x": round(p.x, 4),
            "y": round(p.y, 4),
            "visibility": round(p.visibility, 2),
        }

    return {
        "nose":           lm(0),
        "leftShoulder":   lm(11),
        "rightShoulder":  lm(12),
        "leftElbow":      lm(13),
        "rightElbow":     lm(14),
        "leftWrist":      lm(15),
        "rightWrist":     lm(16),
        "leftHip":        lm(23),
        "rightHip":       lm(24),
        "leftKnee":       lm(25),
        "rightKnee":      lm(26),
        "leftAnkle":      lm(27),
        "rightAnkle":     lm(28),
    }


@router.get("/status")
async def realtime_status():
    """Health-check for the real-time detection endpoint."""
    return {
        "status": "ready",
        "supportedExercises": list(SUPPORTED_EXERCISES.keys()),
        "modelComplexity": 0,
        "targetFps": 2,
        "message": "Real-time posture detection ready",
    }
