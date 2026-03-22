# analyzers/squat.py
from utils.angles import calculate_angle, get_landmark_coords, get_visibility
from utils.landmarks import (
    LEFT_HIP, LEFT_KNEE, LEFT_ANKLE, LEFT_SHOULDER,
    RIGHT_HIP, RIGHT_KNEE, RIGHT_ANKLE, RIGHT_SHOULDER,
)

def analyze_squat(landmarks):
    """
    Analyzes squat form and returns feedback + score
    Key checkpoints:
    - Knee angle (should be ~90° at bottom)
    - Back angle (should stay upright)
    - Knee over toes (knees shouldn't cave inward)
    """
    feedback = []
    deductions = []
    score = 100

    try:
        # ── Left side landmarks ──
        l_hip    = get_landmark_coords(landmarks, LEFT_HIP)
        l_knee   = get_landmark_coords(landmarks, LEFT_KNEE)
        l_ankle  = get_landmark_coords(landmarks, LEFT_ANKLE)
        l_shoulder = get_landmark_coords(landmarks, LEFT_SHOULDER)

        # ── Right side landmarks ──
        r_hip    = get_landmark_coords(landmarks, RIGHT_HIP)
        r_knee   = get_landmark_coords(landmarks, RIGHT_KNEE)
        r_ankle  = get_landmark_coords(landmarks, RIGHT_ANKLE)
        r_shoulder = get_landmark_coords(landmarks, RIGHT_SHOULDER)

        # ── Calculate angles ──
        l_knee_angle = calculate_angle(l_hip, l_knee, l_ankle)
        r_knee_angle = calculate_angle(r_hip, r_knee, r_ankle)
        avg_knee_angle = (l_knee_angle + r_knee_angle) / 2

        l_back_angle = calculate_angle(l_shoulder, l_hip, l_knee)
        r_back_angle = calculate_angle(r_shoulder, r_hip, r_knee)
        avg_back_angle = (l_back_angle + r_back_angle) / 2

        # ── Check 1: Squat depth ──
        if avg_knee_angle > 160:
            feedback.append("⬇️ Go lower — you're barely squatting!")
            deductions.append(25)
        elif avg_knee_angle > 110:
            feedback.append("⬇️ Go a bit deeper — aim for 90° knee bend")
            deductions.append(15)
        elif avg_knee_angle < 60:
            feedback.append("⚠️ Too deep — risk of knee strain")
            deductions.append(10)
        else:
            feedback.append("✅ Good squat depth!")

        # ── Check 2: Back posture ──
        if avg_back_angle < 140:
            feedback.append("🔙 Keep your back straight — you're leaning too far forward")
            deductions.append(20)
        else:
            feedback.append("✅ Good back posture!")

        # ── Check 3: Knee symmetry ──
        knee_diff = abs(l_knee_angle - r_knee_angle)
        if knee_diff > 15:
            feedback.append("⚖️ Uneven squat — both legs should bend equally")
            deductions.append(10)

        # ── Calculate final score ──
        score = max(0, score - sum(deductions))

        return {
            "exercise": "squat",
            "score": score,
            "grade": get_grade(score),
            "feedback": feedback,
            "angles": {
                "leftKnee": l_knee_angle,
                "rightKnee": r_knee_angle,
                "backAngle": round(avg_back_angle, 1)
            },
            "recommendation": get_recommendation(score)
        }

    except Exception as e:
        return {"error": f"Could not analyze squat: {str(e)}"}


def get_grade(score):
    if score >= 90: return "A"
    if score >= 75: return "B"
    if score >= 60: return "C"
    return "D"


def get_recommendation(score):
    if score >= 90: return "🏆 Excellent form! You can increase weight or reps."
    if score >= 75: return "💪 Good form! Minor adjustments will perfect it."
    if score >= 60: return "📚 Focus on form before adding more weight."
    return "🎯 Practice bodyweight squats first to build proper form."