import 'package:flutter/material.dart';
import 'package:fitfusion/gender_selection_page.dart';
import 'dart:math' as math;

class FitnessLevelPage extends StatefulWidget {
  final int age;
  final double weight;
  const FitnessLevelPage({super.key, required this.age, required this.weight});

  @override
  State<FitnessLevelPage> createState() => _FitnessLevelPageState();
}

class _FitnessLevelPageState extends State<FitnessLevelPage> {
  double _fitnessLevel = 3.0;

  final Map<int, String> _descriptions = {
    1: "Beginner",
    2: "Intermediate",
    3: "Somewhat Active",
    4: "Advanced",
    5: "Athlete",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Assessment",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "3 of 6",
                      style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "How would you rate your fitness level?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.question_mark,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Drag to adjust",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            _handleDrag(
                              details.localPosition,
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                          },
                          onTapUp: (details) {
                            _handleDrag(
                              details.localPosition,
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                          },
                          child: CustomPaint(
                            painter: FitnessArcPainter(
                              fitnessLevel: _fitnessLevel,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        right: 40,
                        top: constraints.maxHeight / 2 - 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${_fitnessLevel.round()}",
                              style: const TextStyle(
                                fontSize: 120,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _descriptions[_fitnessLevel.round()] ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    String levelStr = _descriptions[_fitnessLevel.round()] ?? "Beginner";
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenderSelectionPage(
                          age: widget.age,
                          weight: widget.weight,
                          fitnessLevel: levelStr,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDrag(Offset position, double width, double height) {
    final center = Offset(width * 0.8, height / 2);

    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    double angle = math.atan2(dy, dx);

    if (angle < 0) {
      angle += 2 * math.pi;
    }

    const double angleMin = 2.5;
    const double angleMax = 3.8;

    if (angle < angleMin) angle = angleMin;
    if (angle > angleMax) angle = angleMax;

    double t = (angle - angleMin) / (angleMax - angleMin);
    double newLevel = 1.0 + (t * 4.0);

    setState(() {
      _fitnessLevel = newLevel.clamp(1.0, 5.0);
    });
  }
}

class FitnessArcPainter extends CustomPainter {
  final double fitnessLevel;

  FitnessArcPainter({required this.fitnessLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint activePaint = Paint()
      ..color = const Color(0xFFFE7235)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Paint inactivePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Paint tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final center = Offset(size.width * 0.8, size.height / 2);
    final radius = size.width * 0.65;

    const double angleMin = 2.5;
    const double angleMax = 3.8;

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, angleMin, angleMax - angleMin, false, inactivePaint);

    double t = (fitnessLevel - 1.0) / 4.0;
    double currentAngle = angleMin + t * (angleMax - angleMin);

    canvas.drawArc(rect, angleMin, currentAngle - angleMin, false, activePaint);

    for (int i = 1; i <= 5; i++) {
      double ti = (i - 1.0) / 4.0;
      double ang = angleMin + ti * (angleMax - angleMin);

      final p1 = Offset(
        center.dx + (radius - 15) * math.cos(ang),
        center.dy + (radius - 15) * math.sin(ang),
      );
      final p2 = Offset(
        center.dx + (radius + 15) * math.cos(ang),
        center.dy + (radius + 15) * math.sin(ang),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    final knobCenter = Offset(
      center.dx + radius * math.cos(currentAngle),
      center.dy + radius * math.sin(currentAngle),
    );

    canvas.save();
    canvas.translate(knobCenter.dx, knobCenter.dy);
    canvas.rotate(currentAngle + math.pi / 2);

    final knobPaint = Paint()..color = const Color(0xFFFE7235);
    final knobSize = 48.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: knobSize, height: knobSize),
      Radius.circular(12),
    );
    canvas.drawRRect(rrect, knobPaint);

    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, 8, iconPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
