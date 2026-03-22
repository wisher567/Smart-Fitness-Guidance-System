import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fitfusion/screens/posture/widgets/score_ring.dart';
import 'package:fitfusion/screens/posture/widgets/feedback_card.dart';
import 'package:fitfusion/screens/posture/widgets/angle_display.dart';

class PostureResultScreen extends StatefulWidget {
  final Map<String, dynamic> analysisResult;
  final String exerciseName;
  final File imageFile;

  const PostureResultScreen({
    super.key,
    required this.analysisResult,
    required this.exerciseName,
    required this.imageFile,
  });

  @override
  State<PostureResultScreen> createState() => _PostureResultScreenState();
}

class _PostureResultScreenState extends State<PostureResultScreen> {
  late ConfettiController _confettiController;
  bool _isSaving = false;
  bool _saved = false;

  // Theme helpers
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  static const Color primaryColor = Color(0xFFFE7235);
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white54 : Colors.black54;
  Color get borderColor => isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
  Color get surfaceColor => isDark ? const Color(0xFF2A2A2D) : const Color(0xFFF0F0F0);

  // Parsed data
  late int score;
  late String grade;
  late String recommendation;
  late List<String> feedback;
  late Map<String, dynamic> angles;
  late int pointsEarned;
  late bool detected;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _parseResult();

    if (score >= 90) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _parseResult() {
    final result = widget.analysisResult;
    detected = result['detected'] as bool? ?? true;
    pointsEarned = result['pointsEarned'] as int? ?? 0;

    final analysis = result['analysis'] as Map<String, dynamic>? ?? {};
    score = (analysis['score'] as num?)?.toInt() ?? 0;
    grade = analysis['grade'] as String? ?? 'C';
    recommendation =
        analysis['recommendation'] as String? ?? 'Keep working on your form!';
    feedback = List<String>.from(analysis['feedback'] as List? ?? []);
    angles = analysis['angles'] as Map<String, dynamic>? ?? {};
  }

  Color get _scoreColor {
    if (score >= 90) return const Color(0xFF4CAF50);
    if (score >= 75) return const Color(0xFF8BC34A);
    if (score >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _exerciseEmoji(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('squat')) return '🏋️';
    if (lower.contains('push')) return '💪';
    if (lower.contains('plank')) return '🧘';
    return '🏃';
  }

  Future<void> _saveToHistory() async {
    if (_saved) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('posture_history');
      final history = existing != null
          ? List<Map<String, dynamic>>.from(json.decode(existing) as List)
          : <Map<String, dynamic>>[];

      history.insert(0, {
        ...widget.analysisResult,
        'analyzedAt': DateTime.now().toIso8601String(),
        'exerciseName': widget.exerciseName,
      });

      await prefs.setString('posture_history', json.encode(history));

      if (mounted) {
        setState(() {
          _isSaving = false;
          _saved = true;
        });
        _showSnackBar('Analysis saved! +$pointsEarned points 🎉');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Could not save. Try again.', isError: true);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareScore() {
    final ex = widget.exerciseName;
    final emoji = _exerciseEmoji(ex);
    final text =
        '$emoji My $ex posture score: $score/100 (Grade $grade)\n'
        '$recommendation\n'
        'Analyzed with FitFusion 💪';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $text',
            style: GoogleFonts.poppins(fontSize: 11)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Analysis Result',
          style: GoogleFonts.poppins(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: textSecondary),
            onPressed: _shareScore,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageWithScoreOverlay(
                      MediaQuery.of(context).size.height),
                  const SizedBox(height: 6),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: ScoreRing(
                      score: score,
                      grade: grade,
                      recommendation: recommendation,
                      pointsEarned: pointsEarned,
                    ),
                  ),
                  _buildSection(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Form Feedback',
                    child: FeedbackCard(feedbackItems: feedback),
                  ),
                  if (angles.isNotEmpty)
                    _buildSection(
                      icon: Icons.science_outlined,
                      title: 'Joint Angles',
                      child: AngleDisplay(
                        angles: angles,
                        exercise: widget.exerciseName,
                      ),
                    ),
                  _buildSection(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'How to Improve',
                    child: _buildImprovementSection(),
                  ),
                  _buildSection(
                    icon: Icons.smart_toy_outlined,
                    title: '',
                    child: _buildAICoachCard(),
                    noPadding: true,
                  ),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [
                Color(0xFF00E676),
                Color(0xFFFFEB3B),
                Color(0xFF2196F3),
                Color(0xFFF44336),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (AppBar handles header now — _buildHeader removed)

  Widget _buildImageWithScoreOverlay(double screenHeight) {
    final emoji = _exerciseEmoji(widget.exerciseName);

    return SizedBox(
      height: screenHeight * 0.32,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(widget.imageFile, fit: BoxFit.cover),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha(200),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Score badge top right
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _scoreColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _scoreColor.withAlpha(120),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    grade,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().scale(delay: 400.ms, duration: 400.ms,
                begin: const Offset(0, 0)),
          ),
          // Exercise name badge bottom left
          Positioned(
            bottom: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(178),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$emoji ${widget.exerciseName}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
    bool noPadding = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildImprovementSection() {
    if (score >= 90) {
      return _celebrationCard();
    } else if (score >= 75) {
      return _improvementTips(_warningFeedback(), 2);
    } else if (score >= 60) {
      return _improvementTips(_warningFeedback(), 3);
    } else {
      return _beginnerCard();
    }
  }

  List<String> _warningFeedback() {
    return feedback.where((f) => f.startsWith('⚠️') || f.startsWith('❌')).toList();
  }

  Widget _celebrationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withAlpha(80)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding Form!',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4CAF50),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your form is excellent. Focus on progressive overload.',
                  style: GoogleFonts.poppins(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95), delay: 400.ms);
  }

  Widget _beginnerCard() {
    String mod = '';
    final lower = widget.exerciseName.toLowerCase();
    if (lower.contains('squat')) {
      mod = 'Wall Squat: Stand against wall, slide down slowly';
    } else if (lower.contains('push')) {
      mod = 'Knee Push Up: Keep knees on ground for support';
    } else if (lower.contains('plank')) {
      mod = 'Forearm Plank: More stable base, easier to hold';
    } else {
      mod = 'Start with lighter intensity and focus on range of motion';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try the easier variation first:',
            style: GoogleFonts.poppins(color: textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mod,
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _improvementTips(List<String> warnings, int maxTips) {
    final tips = warnings.take(maxTips).toList();
    if (tips.isEmpty) {
      return Text(
        'Focus on maintaining consistency in your form.',
        style: GoogleFonts.poppins(color: textSecondary, fontSize: 13),
      );
    }
    return Column(
      children: tips.asMap().entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                  left: BorderSide(color: primaryColor, width: 3)),
              boxShadow: isDark
                  ? []
                  : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔧', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (e.key * 100).ms),
        );
      }).toList(),
    );
  }

  Widget _buildAICoachCard() {
    final ex = widget.exerciseName;
    final worst = feedback
        .where((f) => f.startsWith('⚠️') || f.startsWith('❌'))
        .firstOrNull
        ?.replaceAll(RegExp(r'^[⚠️❌✅⬇️]\s*'), '') ?? 'form technique';

    String tip;
    if (score >= 90) {
      tip = 'Amazing work! Your $ex form is on point. Keep this consistency '
          'and try adding weight/reps progressively.';
    } else if (score >= 75) {
      tip = 'Good effort on the $ex! Focus on: $worst. '
          'One small fix at a time leads to perfect form.';
    } else {
      tip = 'Keep practicing! The $ex takes time to master. '
          'Start with lighter weight and focus on: $worst.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(isDark ? 25 : 15),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: primaryColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'FitBot Coaching Tip',
                style: GoogleFonts.poppins(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tip,
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          // Try Again
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Try Again',
                  style: GoogleFonts.poppins(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
          const SizedBox(height: 12),
          // Save to History
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saved ? null : _saveToHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _saved ? Colors.grey.shade400 : primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: _saved ? 0 : 4,
                shadowColor: primaryColor.withAlpha(80),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _saved ? '✅ Saved!' : '💾 Save Analysis',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
