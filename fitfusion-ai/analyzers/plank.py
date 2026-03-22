# analyzers/plank.py
from utils.angles import calculate_angle, get_landmark_coords
from utils.landmarks import (
    LEFT_SHOULDER, LEFT_HIP, LEFT_ANKLE, LEFT_KNEE, LEFT_EAR,
)

def analyze_plank(landmarks):
    """
    Analyzes plank form
    Key checkpoints:
    - Body must be straight (shoulder → hip → ankle)
    - Hip position (no sagging or piking)
    - Head neutral (not drooping or lifting)
    """
    feedback = []
    deductions = []
    score = 100

    try:
        l_shoulder = get_landmark_coords(landmarks, LEFT_SHOULDER)
        l_hip      = get_landmark_coords(landmarks, LEFT_HIP)
        l_ankle    = get_landmark_coords(landmarks, LEFT_ANKLE)
        l_knee     = get_landmark_coords(landmarks, LEFT_KNEE)
        l_ear      = get_landmark_coords(landmarks, LEFT_EAR)

        body_angle = calculate_angle(l_shoulder, l_hip, l_ankle)
        hip_angle  = calculate_angle(l_shoulder, l_hip, l_knee)
        neck_angle = calculate_angle(l_ear, l_shoulder, l_hip)

        # ── Check 1: Body straight ──
        if body_angle < 160:
            feedback.append("⬆️ Hips too high — lower them to form a straight line")
            deductions.append(25)
        elif body_angle > 175:
            feedback.append("⬇️ Hips sagging — raise them and squeeze your core")
            deductions.append(25)
        else:
            feedback.append("✅ Perfect body alignment!")

        # ── Check 2: Hip position ──
        if hip_angle < 170:
            feedback.append("🍑 Keep your hips level — don't let them drop")
            deductions.append(15)

        # ── Check 3: Neck neutral ──
        if neck_angle < 150:
            feedback.append("👀 Keep your neck neutral — look at the floor")
            deductions.append(10)
        else:
            feedback.append("✅ Good neck position!")

        score = max(0, score - sum(deductions))

        return {
            "exercise": "plank",
            "score": score,
            "grade": get_grade(score),
            "feedback": feedback,
            "angles": {
                "bodyAngle": round(body_angle, 1),
                "hipAngle": round(hip_angle, 1),
                "neckAngle": round(neck_angle, 1)
            },
            "recommendation": get_recommendation(score)
        }

    except Exception as e:
        return {"error": f"Could not analyze plank: {str(e)}"}


def get_grade(score):
    if score >= 90: return "A"
    if score >= 75: return "B"
    if score >= 60: return "C"
    return "D"


def get_recommendation(score):
    if score >= 90: return "🏆 Rock solid plank!"
    if score >= 75: return "💪 Good plank! Focus on breathing steadily."
    if score >= 60: return "📚 Build core strength with shorter holds first."
    return "🎯 Start with 10-second holds and build up gradually."