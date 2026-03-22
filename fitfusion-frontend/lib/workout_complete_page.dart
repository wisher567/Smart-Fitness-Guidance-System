import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/providers/calorie_provider.dart';

// ─── Palette (matches ExerciseDetailScreen) ──────────────────────────────────
const _accent = Color(0xFFE8845C);
const _bg = Color(0xFFF5F5F5);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF9E9E9E);
const _purple = Color(0xFF9B59B6);
const _dark = Color(0xFF1A1A1A);

/// Screen shown after completing an exercise in ExerciseDetailScreen.
/// Saves the workout to the backend, updates CalorieProvider, and lets
/// the user rate the workout before returning to the home screen.
class WorkoutCompletePage extends StatefulWidget {
  /// Provide these when navigating from ExerciseDetailScreen.
  final String workoutName; // existing field name kept for backward compat
  final String? exerciseName; // alias; workoutName is used if null
  final int sets;
  final int repsCount;
  final int caloriesBurned;
  final int durationSeconds;
  final String? workoutId; // backend ID, if the workout was pre-created

  const WorkoutCompletePage({
    super.key,
    required this.workoutName,
    this.exerciseName,
    this.sets = 0,
    this.repsCount = 0,
    this.caloriesBurned = 0,
    this.durationSeconds = 0,
    this.workoutId,
  });

  @override
  State<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends State<WorkoutCompletePage> {
  int _rating = 5;
  bool _isSaving = false;
  bool _saved = false;
  bool _hasError = false;

  String get _displayName => widget.exerciseName ?? widget.workoutName;

  @override
  void initState() {
    super.initState();
    // Save to backend directly; optimistic update happens after save succeeds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveToBackend();
    });
  }

  Future<void> _saveToBackend() async {
    setState(() => _isSaving = true);
    try {
      if (widget.workoutId != null && widget.workoutId!.isNotEmpty) {
        await ApiService.instance.completeWorkout(widget.workoutId!, _rating);
      } else {
        // No pre-existing workout ID — log the workout as a completion event
        await ApiService.instance.logCompletedWorkout(
          exerciseName: _displayName,
          sets: '${widget.sets}',
          reps: '${widget.repsCount}',
          caloriesBurned: widget.caloriesBurned,
          durationSeconds: widget.durationSeconds,
          rating: _rating,
        );
      }
      if (mounted) {
        context.read<CalorieProvider>().onWorkoutCompleted(
          widget.caloriesBurned,
          _displayName,
        );
        setState(() { _saved = true; _isSaving = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _hasError = true; _isSaving = false; });
    }
  }

  Future<void> _submitRating() async {
    // Re-submit rating if it changed after the initial save
    if (_saved && widget.workoutId != null && widget.workoutId!.isNotEmpty) {
      try {
        await ApiService.instance.completeWorkout(widget.workoutId!, _rating);
      } catch (_) {}
    }
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _fmtTime(int seconds) {
    if (seconds <= 0) return '0m 0s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textPrimary),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        title: Text(
          'Workout Complete',
          style: GoogleFonts.inter(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: w * 0.045,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── Title ──────────────────────────────────────────────
            Text(
              '$_displayName Completed! 🎉',
              style: GoogleFonts.inter(
                fontSize: (w * 0.065).clamp(20.0, 30.0).toDouble(),
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text('Saving…',
                    style: GoogleFonts.inter(color: _textSecondary, fontSize: 12)),
                ]),
              )
            else if (_saved)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Text('Saved', style: GoogleFonts.inter(color: Colors.green, fontSize: 12)),
              ])
            else if (_hasError)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.cloud_off_rounded, color: _textSecondary, size: 14),
                const SizedBox(width: 4),
                Text('Saved locally', style: GoogleFonts.inter(color: _textSecondary, fontSize: 12)),
              ]),

            const SizedBox(height: 28),

            // ── Donut chart ────────────────────────────────────────
            _buildPieChart(w),
            const SizedBox(height: 16),

            // ── Legend ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(_accent, 'Sets'),
                const SizedBox(width: 20),
                _legendDot(_purple, 'Calories'),
                const SizedBox(width: 20),
                _legendDot(_dark, 'Duration'),
              ],
            ),

            const SizedBox(height: 28),

            // ── Stats row ─────────────────────────────────────────
            _buildStatsRow(),

            const SizedBox(height: 36),

            // ── Star rating ───────────────────────────────────────
            Text(
              'Rate your workout',
              style: GoogleFonts.inter(
                fontSize: (w * 0.045).clamp(16.0, 20.0).toDouble(),
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _accent,
                      size: (w * 0.1).clamp(32.0, 48.0).toDouble(),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),

      // ── Bottom CTA ────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: _isSaving ? null : _submitRating,
            child: _isSaving
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                    SizedBox(width: 10),
                    Text('Saving…', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ])
                : Text(
                    'Great, Thanks! 🎉',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Pie chart (donut) ──────────────────────────────────────────────────────
  Widget _buildPieChart(double w) {
    // Guard against all-zero data to avoid fl_chart errors
    final sets = widget.sets > 0 ? widget.sets.toDouble() : 1.0;
    final cals = widget.caloriesBurned > 0 ? widget.caloriesBurned.toDouble() : 1.0;
    final dur = widget.durationSeconds > 0 ? widget.durationSeconds.toDouble() : 1.0;

    final sectionRadius = (w * 0.14).clamp(45.0, 60.0).toDouble();
    final centerRadius = (w * 0.14).clamp(50.0, 70.0).toDouble();

    return SizedBox(
      height: (w * 0.55).clamp(180.0, 240.0).toDouble(),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: centerRadius,
          sections: [
            PieChartSectionData(
              value: sets,
              color: _accent,
              title: '${widget.sets}',
              titleStyle: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              radius: sectionRadius,
            ),
            PieChartSectionData(
              value: cals,
              color: _purple,
              title: '${widget.caloriesBurned}',
              titleStyle: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              radius: sectionRadius,
            ),
            PieChartSectionData(
              value: dur,
              color: _dark,
              title: _fmtTime(widget.durationSeconds),
              titleStyle: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              radius: sectionRadius,
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats strip ───────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('${widget.sets}', 'Sets', Icons.repeat_rounded),
          _vDivider(),
          _statItem('${widget.repsCount}', 'Reps', Icons.fitness_center_rounded),
          _vDivider(),
          _statItem('${widget.caloriesBurned}', 'kcal',
              Icons.local_fire_department_rounded),
          _vDivider(),
          _statItem(_fmtTime(widget.durationSeconds), 'Time', Icons.timer_rounded),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Flexible(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: _accent, size: 20),
        const SizedBox(height: 4),
        Text(value,
          style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary),
          overflow: TextOverflow.ellipsis),
        Text(label,
          style: GoogleFonts.inter(fontSize: 11, color: _textSecondary)),
      ]),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: const Color(0xFFE0E0E0));

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label,
        style: GoogleFonts.inter(color: _textSecondary, fontSize: 12)),
    ]);
  }
}
