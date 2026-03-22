import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitfusion/screens/exercise_detail_screen.dart';
import 'package:fitfusion/models/exercise_model.dart';
import 'package:provider/provider.dart';
import 'package:fitfusion/providers/calorie_provider.dart';
import 'workout_complete_page.dart';

class WorkoutExercisesPage extends StatefulWidget {
  final String workoutName;
  const WorkoutExercisesPage({super.key, required this.workoutName});

  @override
  State<WorkoutExercisesPage> createState() => _WorkoutExercisesPageState();
}

class _WorkoutExercisesPageState extends State<WorkoutExercisesPage> {
  int? _activeIndex;

  String get _description {
    switch (widget.workoutName) {
      case 'Back Workout':
        return 'Forge a powerful, V-tapered back. Develop thickness and wide width with targeted exercise daily.';
      case 'Leg Workout':
        return 'Sculpt powerful, explosive legs. Build foundation and strength with focused lower-body training.';
      case 'Shoulder Workout':
        return 'Define broad, capped shoulders. Enhance stability and overhead power with elite delt training.';
      case 'Abs Workout':
        return 'Forge a chiseled, stable core. Sculpt definition and functional strength with precision abdominal training.';
      case 'Forearm Workout':
        return 'Build iron-clad grip strength. Develop density and vascularity with targeted isolation training.';
      case 'Chest Workout':
        return 'Carve a powerful, expansive chest. Maximize pectoral density and width with heavy, targeted pressing.';
      default:
        return 'Build strength, endurance and muscle with this targeted workout routine.';
    }
  }

  List<Map<String, dynamic>> get _exercises {
    switch (widget.workoutName) {
      case 'Back Workout':
        return [
          {'name': 'Pull ups', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Cycling', 'detail': '20 min', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Running', 'detail': '10 min', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Push ups', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Set ups', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Swimming', 'detail': '10 min', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Stretching', 'detail': '10 min', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Weight lifting', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Jumping', 'detail': '5 min', 'asset': 'assets/images/workout_bg.png'},
        ];
      case 'Leg Workout':
        return [
          {'name': 'Back squats', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Deadlifts', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Leg press', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Split squats', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Lunges', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Step ups', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Calf raises', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Leg curl', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Quads', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
        ];
      case 'Shoulder Workout':
        return [
          {'name': 'Military press', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Arnold press', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Push press', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Side raises', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Front raises', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Face pulls', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Rear flyers', 'detail': '10x4reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Upright rows', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Dumbbell shrugs', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
        ];
      case 'Abs Workout':
        return [
          {'name': 'Crunches', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Planks', 'detail': '10 min', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Leg raises', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Twists', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Side plank', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Bicycle', 'detail': '10 min', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'V sits', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Mount climb', 'detail': '15 min', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Toe-touch', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
        ];
      case 'Forearm Workout':
        return [
          {'name': 'Wrist curls', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Reverse curl', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Wrists rollers', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Farmer carries', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Plate punches', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Dead hangs', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Hammer curls', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Towel pullups', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Wrist rotation', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
        ];
      case 'Chest Workout':
        return [
          {'name': 'Bench press', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Incline press', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Decline press', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Dumbbell flyers', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Cable cross', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Pec deck', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Push ups', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Chest dips', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
          {'name': 'Dumbbell pullover', 'detail': '10x4 reps', 'asset': 'assets/images/workout_bg.png'},
        ];
      default:
        return List.generate(6, (i) => {
          'name': 'Exercise ${i + 1}',
          'detail': '10x4 reps',
          'asset': 'assets/images/workout_bg.png',
        });
    }
  }

  void _showExerciseTimer(BuildContext context, ExerciseModel exercise, int index) {
    setState(() => _activeIndex = index);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseTimerSheet(
        exercise: exercise,
        onClose: () {
          Navigator.pop(context);
          setState(() => _activeIndex = null);
        },
        onComplete: (int caloriesBurned, int durationSeconds) {
          Navigator.pop(context);
          setState(() => _activeIndex = null);
          // Optimistically update CalorieProvider so the calorie page refreshes immediately
          context.read<CalorieProvider>().onWorkoutCompleted(caloriesBurned, exercise.name);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutCompletePage(
                workoutName: exercise.name,
                sets: exercise.sets,
                repsCount: exercise.reps.isNotEmpty
                    ? (int.tryParse(RegExp(r'\d+').firstMatch(exercise.reps)?.group(0) ?? '10') ?? 10)
                    : 10,
                caloriesBurned: caloriesBurned,
                durationSeconds: durationSeconds,
              ),
            ),
          );
        },
      ),
    ).whenComplete(() => setState(() => _activeIndex = null));
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _exercises;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        children: [
          // ── Dark top header ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.fitness_center, color: Colors.white70, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${exercises.length} Total',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.workoutName,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _description,
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Exercise list ────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF8F8F8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Workouts',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        Text(
                          'See All',
                          style: GoogleFonts.inter(color: const Color(0xFFFE7235), fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ex = exercises[index];
                        final isActive = _activeIndex == index;
                        final exerciseModel = exerciseFromName(ex['name'] as String);
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => ExerciseDetailScreen(exercise: exerciseModel),
                              transitionsBuilder: (_, animation, __, child) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                            ),
                          ),
                          child: _ExerciseRow(
                            name: ex['name'] as String,
                            detail: ex['detail'] as String,
                            assetPath: exerciseModel.youtubeThumbnail ?? ex['asset'] as String,
                            isActive: isActive,
                            onStart: () => _showExerciseTimer(context, exerciseModel, index),
                            onStop: () => setState(() {
                              if (_activeIndex == index) _activeIndex = null;
                            }),
                            onVideo: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => ExerciseDetailScreen(exercise: exerciseModel),
                                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Timer Bottom Sheet ─────────────────────────────────────────────
class _ExerciseTimerSheet extends StatefulWidget {
  final ExerciseModel exercise;
  final VoidCallback onClose;
  /// Called with (caloriesBurned, durationSeconds) when the user taps Done.
  final void Function(int caloriesBurned, int durationSeconds) onComplete;

  const _ExerciseTimerSheet({
    required this.exercise,
    required this.onClose,
    required this.onComplete,
  });

  @override
  State<_ExerciseTimerSheet> createState() => _ExerciseTimerSheetState();
}

class _ExerciseTimerSheetState extends State<_ExerciseTimerSheet>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFFFE7235);
  static const _bg = Color(0xFF1A1A1A);

  late int _currentSet;
  late int _secondsRemaining;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  bool _isCompleted = false;
  Timer? _timer;
  Timer? _elapsedTimer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _currentSet = 1;
    _secondsRemaining = widget.exercise.restSeconds > 0
        ? widget.exercise.restSeconds * 2
        : 45;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startTimer();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || !mounted) return;
      if (_secondsRemaining <= 0) {
        _advanceSet();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _advanceSet() {
    if (_currentSet >= widget.exercise.sets) {
      _timer?.cancel();
      setState(() => _isCompleted = true);
    } else {
      setState(() {
        _currentSet++;
        _secondsRemaining = widget.exercise.restSeconds > 0
            ? widget.exercise.restSeconds * 2
            : 45;
      });
    }
  }

  void _togglePause() => setState(() => _isPaused = !_isPaused);

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: _isCompleted ? _buildCompletedView() : _buildTimerView(),
    );
  }

  Widget _buildTimerView() {
    final ex = widget.exercise;
    final progress = _currentSet / ex.sets;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Exercise name
          Text(
            ex.name,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            ex.muscleGroup,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Sets row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(ex.sets, (i) {
              final done = i < _currentSet - 1;
              final active = i == _currentSet - 1;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 32 : 20,
                height: 8,
                decoration: BoxDecoration(
                  color: done
                      ? Colors.green
                      : active
                          ? _accent
                          : Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Set $_currentSet of ${ex.sets}',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),

          // Big Timer
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              final scale = _isPaused ? 1.0 : 1.0 + _pulseController.value * 0.025;
              return Transform.scale(scale: scale, child: child);
            },
            child: Text(
              _fmt(_secondsRemaining),
              style: GoogleFonts.inter(
                color: _isPaused ? Colors.white38 : _accent,
                fontSize: 72,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isPaused ? 'PAUSED' : 'REST TIMER',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(_accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 28),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statBox(Icons.repeat_rounded, '${ex.sets}', 'Sets'),
              _statBox(Icons.fitness_center_rounded, ex.reps, 'Reps'),
              _statBox(Icons.timer_outlined, ex.restDisplay, 'Rest'),
              _statBox(Icons.local_fire_department_outlined, '${ex.estimatedCalories}', 'kcal'),
            ],
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              // Close
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: widget.onClose,
                  child: Text('Stop', style: GoogleFonts.inter(color: Colors.white54, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              // Skip Set
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _accent.withAlpha(100)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _advanceSet,
                  child: Text('Skip Set', style: GoogleFonts.inter(color: _accent, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              // Pause/Resume
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _togglePause,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        _isPaused ? 'Resume' : 'Pause',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
          ),
          const SizedBox(height: 16),
          Text('Exercise Complete! 🎉', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${widget.exercise.estimatedCalories} kcal burned',
            style: GoogleFonts.inter(color: _accent, fontSize: 16),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => widget.onComplete(
                widget.exercise.estimatedCalories,
                _elapsedSeconds,
              ),
              child: Text('Done', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onClose,
            child: Text('Back to List', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: _accent, size: 20),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

// ── Individual exercise row ─────────────────────────────────────────────────
class _ExerciseRow extends StatelessWidget {
  final String name;
  final String detail;
  final String assetPath;
  final bool isActive;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onVideo;

  const _ExerciseRow({
    required this.name,
    required this.detail,
    required this.assetPath,
    required this.isActive,
    required this.onStart,
    required this.onStop,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isActive
            ? Border.all(color: const Color(0xFFFE7235), width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: assetPath.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: assetPath,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.fitness_center, color: Colors.grey),
                      ),
                    )
                  : Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.fitness_center, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + detail + buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Start button
                    GestureDetector(
                      onTap: onStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFFE7235) : const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isActive ? 'Active' : 'Start',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Video icon
          GestureDetector(
            onTap: onVideo,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.videocam_outlined, size: 22, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
