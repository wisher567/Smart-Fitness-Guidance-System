import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScoreRing extends StatelessWidget {
  final int score;
  final String grade;
  final String recommendation;
  final int pointsEarned;

  const ScoreRing({
    super.key,
    required this.score,
    required this.grade,
    required this.recommendation,
    required this.pointsEarned,
  });

  Color get _scoreColor {
    if (score >= 90) return const Color(0xFF00E676);
    if (score >= 75) return const Color(0xFF69F0AE);
    if (score >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get _scoreLabel {
    if (score >= 90) return 'Excellent!';
    if (score >= 75) return 'Good Form!';
    if (score >= 60) return 'Needs Work';
    return 'Keep Practicing';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Score Ring
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 10.0,
            animation: true,
            animationDuration: 1500,
            percent: (score / 100).clamp(0.0, 1.0),
            progressColor: _scoreColor,
            backgroundColor: const Color(0xFF252525),
            circularStrokeCap: CircularStrokeCap.round,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
                Text(
                  'Score',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Summary column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grade badge + label row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _scoreColor.withAlpha(38),
                        shape: BoxShape.circle,
                        border: Border.all(color: _scoreColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          grade,
                          style: GoogleFonts.poppins(
                            color: _scoreColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _scoreLabel,
                      style: GoogleFonts.poppins(
                        color: _scoreColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Recommendation
                Text(
                  recommendation,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Points earned badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withAlpha(28),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00E676).withAlpha(77),
                    ),
                  ),
                  child: Text(
                    '+$pointsEarned pts earned',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00E676),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  delay: 800.ms,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
