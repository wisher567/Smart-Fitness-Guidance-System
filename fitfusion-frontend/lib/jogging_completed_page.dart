import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:fitfusion/providers/workout_provider.dart';
import 'package:fitfusion/services/api_service.dart';
import 'calorie_stats_page.dart';

class JoggingCompletedPage extends StatefulWidget {
  final String? workoutId;
  final String? classId;
  final String title;

  const JoggingCompletedPage({
    super.key, 
    this.workoutId, 
    this.classId,
    this.title = "Workout Completed",
  });

  @override
  State<JoggingCompletedPage> createState() => _JoggingCompletedPageState();
}

class _JoggingCompletedPageState extends State<JoggingCompletedPage> {
  double _rating = 0;
  bool _isLoading = false;

  Future<void> _submitAndContinue() async {
    setState(() => _isLoading = true);
    
    // Capture provider reference before any async gaps
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

    try {
      if (widget.classId != null) {
        // Just check in if it's a class
        await ApiService.instance.checkInClass(widget.classId!);
      }
      
      if (widget.workoutId != null) {
        // Complete the workout via provider to refresh history automatically
        await workoutProvider.completeWorkout(
          widget.workoutId!, 
          _rating.toInt() == 0 ? 5 : _rating.toInt() // Default to 5 if no rating
        );
      } else if (widget.classId == null) {
        // If neither was provided, simulate a delay for UX
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CalorieStatsPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Center(
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Donut chart
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: _DonutChartPainter(),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Legend row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(const Color(0xFFF97316), "Distance"),
                  const SizedBox(width: 20),
                  _legendItem(const Color(0xFF9B7FE8), "Calorie"),
                  const SizedBox(width: 20),
                  _legendItem(const Color(0xFF2E2E2E), "BPM"),
                ],
              ),

              const Spacer(flex: 2),

              // Rate your workout
              Center(
                child: Text(
                  "Rate your workout",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  unratedColor: Colors.grey.shade300,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF97316),
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _rating = rating;
                    });
                  },
                ),
              ),

              const Spacer(flex: 2),

              // Great, Thanks button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _submitAndContinue,
                  child: _isLoading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Text(
                          "Great, Thanks",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ── Donut Chart Painter ──────────────────────────────────────────────────────
class _DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 40.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // Segments: Distance 26%, Calorie 24%, BPM 50%
    const segments = [
      (0.26, Color(0xFFF97316), '26%'), // Distance - orange
      (0.24, Color(0xFF9B7FE8), '24%'), // Calorie - purple
      (0.50, Color(0xFF2E2E2E), '50%'), // BPM - dark
    ];

    double startAngle = math.pi / 2; // start from bottom

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final seg in segments) {
      final sweep = seg.$1 * 2 * math.pi;
      paint.color = seg.$2;
      canvas.drawArc(rect, startAngle, sweep - 0.04, false, paint);

      // Label position at the middle of the arc
      final midAngle = startAngle + sweep / 2;

      final tp = TextPainter(
        text: TextSpan(
          text: seg.$3,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Offset label slightly inside the stroke center
      final inRadius = radius - strokeWidth / 2;
      final inX = center.dx + inRadius * math.cos(midAngle);
      final inY = center.dy + inRadius * math.sin(midAngle);

      tp.paint(canvas, Offset(inX - tp.width / 2, inY - tp.height / 2));

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
