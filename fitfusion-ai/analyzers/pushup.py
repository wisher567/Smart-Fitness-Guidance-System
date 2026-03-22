# analyzers/pushup.py
from utils.angles import calculate_angle, get_landmark_coords
from utils.landmarks import (
    LEFT_SHOULDER, LEFT_ELBOW, LEFT_WRIST,
    RIGHT_SHOULDER, RIGHT_ELBOW, RIGHT_WRIST,
    LEFT_HIP, LEFT_KNEE, LEFT_ANKLE,
)

def analyze_pushup(landmarks):
    """
    Analyzes pushup form
    Key checkpoints:
    - Elbow angle (should be ~90° at bottom)
    - Body alignment (straight line from head to heels)
    - Hip position (no sagging or piking)
    """
    feedback = []
    deductions = []
    score = 100

    try:
        # Landmarks
        l_shoulder = get_landmark_coords(landmarks, LEFT_SHOULDER)
        l_elbow    = get_landmark_coords(landmarks, LEFT_ELBOW)
        l_wrist    = get_landmark_coords(landmarks, LEFT_WRIST)

        r_shoulder = get_landmark_coords(landmarks, RIGHT_SHOULDER)
        r_elbow    = get_landmark_coords(landmarks, RIGHT_ELBOW)
        r_wrist    = get_landmark_coords(landmarks, RIGHT_WRIST)

        l_hip      = get_landmark_coords(landmarks, LEFT_HIP)
        l_knee     = get_landmark_coords(landmarks, LEFT_KNEE)
        l_ankle    = get_landmark_coords(landmarks, LEFT_ANKLE)

        # Angles
        l_elbow_angle = calculate_angle(l_shoulder, l_elbow, l_wrist)
        r_elbow_angle = calculate_angle(r_shoulder, r_elbow, r_wrist)
        avg_elbow_angle = (l_elbow_angle + r_elbow_angle) / 2

        body_angle = calculate_angle(l_shoulder, l_hip, l_ankle)

        # ── Check 1: Elbow bend ──
        if avg_elbow_angle > 160:
            feedback.append("⬇️ Go lower — bend your elbows more!")
            deductions.append(25)
        elif avg_elbow_angle > 110:
            feedback.append("⬇️ Lower your chest closer to the ground")
            deductions.append(15)
        elif avg_elbow_angle < 60:
            feedback.append("✅ Great depth on your pushup!")
        else:
            feedback.append("✅ Good elbow position!")

        # ── Check 2: Body alignment ──
        if body_angle < 160:
            feedback.append("📐 Keep your body in a straight line — hips too high!")
            deductions.append(20)
        elif body_angle > 175:
            feedback.append("⚠️ Hips sagging — engage your core!")
            deductions.append(20)
        else:
            feedback.append("✅ Great body alignment!")

        score = max(0, score - sum(deductions))

        return {
            "exercise": "pushup",
            "score": score,
            "grade": get_grade(score),
            "feedback": feedback,
            "angles": {
                "leftElbow": l_elbow_angle,
                "rightElbow": r_elbow_angle,
                "bodyAlignment": round(body_angle, 1)
            },
            "recommendation": get_recommendation(score)
        }

    except Exception as e:
        return {"error": f"Could not analyze pushup: {str(e)}"}


def get_grade(score):
    if score >= 90: return "A"
    if score >= 75: return "B"
    if score >= 60: return "C"
    return "D"


def get_recommendation(score):
    if score >= 90: return "🏆 Perfect pushup form!"
    if score >= 75: return "💪 Good form! Keep your core tight throughout."
    if score >= 60: return "📚 Focus on body alignment before increasing reps."
    return "🎯 Try wall pushups or knee pushups to build strength first."