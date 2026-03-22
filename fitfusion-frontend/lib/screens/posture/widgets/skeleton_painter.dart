import 'package:flutter/material.dart';

/// Normalized landmark position (0.0–1.0)
class LandmarkPoint {
  final double x;
  final double y;
  final double visibility;

  const LandmarkPoint(this.x, this.y, this.visibility);

  /// Lerp toward target for smooth animation between frames
  LandmarkPoint lerpTo(LandmarkPoint target, double t) {
    return LandmarkPoint(
      x + (target.x - x) * t,
      y + (target.y - y) * t,
      target.visibility,
    );
  }
}

/// Draws skeleton overlay (green dots + lines) on the camera feed.
/// Landmark coordinates are normalised 0–1 relative to frame dimensions.
class SkeletonPainter extends CustomPainter {
  final Map<String, LandmarkPoint> landmarks;

  SkeletonPainter({required this.landmarks});

  static const double _minVisibility = 0.5;
  static const double _dotRadius = 6.0;
  static const double _lineWidth = 2.5;

  // Skeleton connections to draw as lines
  static const List<List<String>> _connections = [
    // Arms
    ['leftShoulder', 'leftElbow'],
    ['leftElbow', 'leftWrist'],
    ['rightShoulder', 'rightElbow'],
    ['rightElbow', 'rightWrist'],
    // Torso
    ['leftShoulder', 'rightShoulder'],
    ['leftShoulder', 'leftHip'],
    ['rightShoulder', 'rightHip'],
    ['leftHip', 'rightHip'],
    // Legs
    ['leftHip', 'leftKnee'],
    ['leftKnee', 'leftAnkle'],
    ['rightHip', 'rightKnee'],
    ['rightKnee', 'rightAnkle'],
    // Head → shoulders (approximate neck)
    ['nose', 'leftShoulder'],
    ['nose', 'rightShoulder'],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // ── Draw lines first (under dots) ─────────────────────────────────────
    final linePaint = Paint()
      ..color = const Color(0xFF00E676).withAlpha(178)  // 0.7 opacity
      ..strokeWidth = _lineWidth
      ..strokeCap = StrokeCap.round;

    for (final conn in _connections) {
      final a = landmarks[conn[0]];
      final b = landmarks[conn[1]];
      if (a == null || b == null) continue;
      if (a.visibility < _minVisibility || b.visibility < _minVisibility) continue;

      canvas.drawLine(
        Offset(a.x * size.width, a.y * size.height),
        Offset(b.x * size.width, b.y * size.height),
        linePaint,
      );
    }

    // ── Draw dots ─────────────────────────────────────────────────────────
    for (final entry in landmarks.entries) {
      final lm = entry.value;
      if (lm.visibility < _minVisibility) continue;

      final Color color = lm.visibility > 0.8
          ? const Color(0xFF00E676)   // bright green — high confidence
          : const Color(0xFFFF9800);  // orange — lower confidence

      canvas.drawCircle(
        Offset(lm.x * size.width, lm.y * size.height),
        _dotRadius,
        Paint()..color = color,
      );

      // White border ring
      canvas.drawCircle(
        Offset(lm.x * size.width, lm.y * size.height),
        _dotRadius,
        Paint()
          ..color = Colors.white.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}

/// Converts raw API landmark map to typed [LandmarkPoint] objects.
Map<String, LandmarkPoint> parseLandmarks(Map<String, dynamic>? raw) {
  if (raw == null) return {};
  final result = <String, LandmarkPoint>{};
  raw.forEach((key, value) {
    if (value is Map) {
      result[key] = LandmarkPoint(
        (value['x'] as num? ?? 0).toDouble(),
        (value['y'] as num? ?? 0).toDouble(),
        (value['visibility'] as num? ?? 0).toDouble(),
      );
    }
  });
  return result;
}

/// Smoothly interpolates landmark positions between frames (50% lerp).
Map<String, LandmarkPoint> smoothLandmarks(
  Map<String, LandmarkPoint> previous,
  Map<String, LandmarkPoint> next,
) {
  if (previous.isEmpty) return next;
  final result = <String, LandmarkPoint>{};
  next.forEach((key, newPoint) {
    final old = previous[key];
    result[key] = old != null ? old.lerpTo(newPoint, 0.5) : newPoint;
  });
  return result;
}
