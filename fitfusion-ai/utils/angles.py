# utils/angles.py
import numpy as np

def calculate_angle(a, b, c):
    """
    Calculate angle at point B formed by points A, B, C
    Returns angle in degrees (0-180)
    """
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)

    radians = np.arctan2(c[1] - b[1], c[0] - b[0]) - \
              np.arctan2(a[1] - b[1], a[0] - b[0])

    angle = np.abs(radians * 180.0 / np.pi)

    if angle > 180.0:
        angle = 360 - angle

    return round(angle, 1)


def get_landmark_coords(landmarks, index):
    """Extract x, y coordinates from a MediaPipe landmark by index"""
    lm = landmarks[index]
    return [lm.x, lm.y]


def get_visibility(landmarks, index):
    """Check if landmark is clearly visible"""
    return landmarks[index].visibility > 0.5