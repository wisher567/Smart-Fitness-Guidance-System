import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:fitfusion/models/exercise_model.dart';
import 'package:fitfusion/services/api_service.dart';
import 'package:fitfusion/workout_complete_page.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const _accent     = Color(0xFFE8845C);
const _accentDark = Color(0xFFD4673A);
const _bg         = Color(0xFFF5F5F5);
const _textPrimary   = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF9E9E9E);
const _divider    = Color(0xFFF0F0F0);

// ─── Video ID map ─────────────────────────────────────────────────────────────
const Map<String, String> _exerciseVideoIds = {
  'Pull ups':          'eGo4IYlbE5g',
  'Push ups':          '_l3ySVKYVJ8',
  'Squats':            'aclHkVaku9U',
  'Deadlifts':         'op9kVnSso6Q',
  'Bench press':       'rT7DgCr-3pg',
  'Lunges':            'QOVaHwm-Q6U',
  'Plank':             'pSHjTRCQxIw',
  'Burpees':           'dZgVxmf6jkA',
  'Mountain climbers': 'nmwgirgXLYM',
  'Jumping jacks':     'c4DAnQ6DtF8',
  'Bicep curls':       'ykJmrZ5v0Oo',
  'Tricep dips':       '6kALZikXxLc',
  'Shoulder press':    'qEwKCR5JCog',
  'Leg press':         'IZxyjW7MPJQ',
  'Calf raises':       'gwLzBTABDFU',
  'Back squats':       'U3HlEF_whyg',
  'Arnold press':      '6Z15_WdXmVw',
  'Military press':    'Aelm-Czyz7A',
  'Wrist curls':       'GEzo1JF0r4w',
  'Crunches':          'Xyd_fa5zoEU',
  'Planks':            'pSHjTRCQxIw',
  'Leg raises':        'l4kQd9eWclE',
  'Bicycle':           'GzHG9_L6eDk',
  'Side plank':        'K2VljzCC16g',
  'Running':           'brFHyOtTwH4',
  'Swimming':          'gh5mAtmeR3Y',
  'Cycling':           'mmFMRs6Ynng',
};

// ─── Screen states ────────────────────────────────────────────────────────────
enum _LoadState { loading, ready }

class ExerciseDetailScreen extends StatefulWidget {
  final ExerciseModel exercise;
  final bool autoStart;
  const ExerciseDetailScreen({super.key, required this.exercise, this.autoStart = false});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with TickerProviderStateMixin {

  // ── Misc ──────────────────────────────────────────────────────────────────
  bool _isBookmarked = false;
  _LoadState _loadState = _LoadState.loading;
  List<String> _instructions = [];

  // ── YouTube ───────────────────────────────────────────────────────────────
  YoutubePlayerController? _ytController;
  bool _hasVideo = false;

  // ── Workout Timer ─────────────────────────────────────────────────────────
  bool _showTimer    = false;
  bool _isPaused     = false;
  bool _isCompleted  = false;
  bool _isResting    = false;
  int  _currentSet   = 1;
  int  _currentRep   = 0;
  int  _restSecondsRemaining = 0;
  int  _totalSecondsElapsed  = 0;
  Timer? _elapsedTimer;
  Timer? _restTimer;

  // ── Pulse animation ───────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;

  // ── Helpers ───────────────────────────────────────────────────────────────
  ExerciseModel get _ex => widget.exercise;

  int get _repsCount {
    final m = RegExp(r'\d+').firstMatch(_ex.reps);
    return m != null ? int.parse(m.group(0)!) : 10;
  }

  int get _restSec => _ex.restSeconds > 0 ? _ex.restSeconds : 45;
  int get _totalSets => _ex.sets;

  // ── Init / Dispose ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Pulse animation for Start button
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // YouTube
    final videoId = _exerciseVideoIds[_ex.name];
    if (videoId != null) {
      _hasVideo = true;
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
          loop: false,
        ),
      );
    }

    _loadInstructions();

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startWorkout());
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ytController?.dispose();
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  // ── Instructions API ──────────────────────────────────────────────────────
  Future<void> _loadInstructions() async {
    try {
      final resp = await ApiService.instance.getExerciseInstructions(
        exerciseName: _ex.name,
        difficulty: _ex.difficulty,
        sets: _ex.sets,
        reps: _ex.reps,
      );
      if (!mounted) return;
      final raw = resp.data?['instructions'];
      List<String> parsed = [];
      if (raw is List) {
        parsed = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        final dec = jsonDecode(raw);
        if (dec is List) parsed = dec.map((e) => e.toString()).toList();
      }
      setState(() {
        _instructions = parsed.isNotEmpty ? parsed : _fallback();
        _loadState = _LoadState.ready;
      });
    } catch (_) {
      if (mounted) setState(() { _instructions = _fallback(); _loadState = _LoadState.ready; });
    }
  }

  List<String> _fallback() => [
    'Stand in the correct starting position with feet shoulder-width apart and a neutral spine.',
    'Engage your core and take a deep breath before initiating the movement.',
    'Execute the movement with slow, controlled speed — avoid using momentum.',
    'Exhale fully as you complete the concentric (exertion) phase of each rep.',
    'Return to the starting position slowly under control, then repeat for all reps.',
  ];

  // ── Timer logic ───────────────────────────────────────────────────────────
  void _startWorkout() {
    setState(() {
      _showTimer   = true;
      _currentSet  = 1;
      _currentRep  = 0;
      _isResting   = false;
      _isPaused    = false;
      _isCompleted = false;
      _totalSecondsElapsed = 0;
    });
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) setState(() => _totalSecondsElapsed++);
    });
  }

  void _nextRep() {
    if (_currentRep >= _repsCount) return;
    setState(() => _currentRep++);
    if (_currentRep == _repsCount) {
      _startRestTimer();
    }
  }

  void _startRestTimer() {
    setState(() { _isResting = true; _restSecondsRemaining = _restSec; });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPaused || !mounted) return;
      if (_restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
      } else {
        t.cancel();
        _afterRest();
      }
    });
  }

  void _afterRest() {
    if (_currentSet < _totalSets) {
      setState(() { _currentSet++; _currentRep = 0; _isResting = false; });
    } else {
      _completeWorkout();
    }
  }

  void _skipRest() {
    _restTimer?.cancel();
    _afterRest();
  }

  void _skipSet() {
    _restTimer?.cancel();
    setState(() { _currentRep = _repsCount; });
    _startRestTimer();
  }

  void _completeWorkout() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    setState(() { _isCompleted = true; _isResting = false; });
    _saveWorkout();
  }

  void _saveWorkout() {
    // workoutId is not available on ExerciseModel; completion is handled
    // by WorkoutCompletePage which does the API call.
  }

  void _closeTimer() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _showTimer   = false;
      _isPaused    = false;
      _isCompleted = false;
      _isResting   = false;
      _currentSet  = 1;
      _currentRep  = 0;
    });
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final Widget body = _hasVideo
        ? YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _ytController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: _accent,
              progressColors: const ProgressBarColors(
                playedColor: _accent,
                handleColor: _accentDark,
                bufferedColor: Color(0x55E8845C),
                backgroundColor: Color(0xFFE0E0E0),
              ),
            ),
            builder: (context, player) => _buildScaffold(context, player),
          )
        : _buildScaffold(context, null);

    return body;
  }

  Widget _buildScaffold(BuildContext context, Widget? ytPlayer) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildContent(ytPlayer),
          if (_showTimer) _buildTimerOverlay(),
        ],
      ),
      bottomNavigationBar: _buildStartButton(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_rounded, color: _textPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(_ex.name,
      style: GoogleFonts.inter(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
    centerTitle: true,
    actions: [
      IconButton(
        icon: Icon(_isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _accent),
        onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
      ),
    ],
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(color: _divider, height: 1),
    ),
  );

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildContent(Widget? ytPlayer) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _buildVideoSection(ytPlayer)
            .animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        _buildInfoCard()
            .animate().fadeIn(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
        _buildStatsCard()
            .animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
        _buildMoreVideos()
            .animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
        _buildInstructions()
            .animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }

  // ── Video section ─────────────────────────────────────────────────────────
  Widget _buildVideoSection(Widget? ytPlayer) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.28,
          width: double.infinity,
          child: ytPlayer ?? Container(
                  color: const Color(0xFFF0EDE8),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off_rounded, color: Color(0xFFCCCCCC), size: 48),
                      SizedBox(height: 8),
                      Text('Video coming soon',
                          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_ex.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(height: 6),
          Text(_ex.muscleGroup, style: GoogleFonts.inter(fontSize: 14, color: _textSecondary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(_ex.category, outlined: true, accent: true),
            _chip(_ex.difficulty, filled: true),
            _chip('No Equipment', outlined: true, accent: false),
          ]),
        ],
      ),
    );
  }

  Widget _chip(String label, {bool outlined = false, bool filled = false, bool accent = false}) {
    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    if (outlined && accent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _accent.withAlpha(20),
          border: Border.all(color: _accent, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.inter(color: _accent, fontSize: 12)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _bg, border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.inter(color: _textSecondary, fontSize: 12)),
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(children: [
        _stat(Icons.repeat_rounded,            _ex.setsDisplay,     'Sets'),
        _vDiv(),
        _stat(Icons.fitness_center_rounded,    _ex.reps,            'Reps'),
        _vDiv(),
        _stat(Icons.timer_outlined,            _ex.restDisplay,     'Rest'),
        _vDiv(),
        _stat(Icons.local_fire_department_outlined, _ex.caloriesDisplay, 'kcal'),
      ]),
    );
  }

  Widget _stat(IconData icon, String val, String lbl) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _accent, size: 22),
      const SizedBox(height: 6),
      Text(val, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
      const SizedBox(height: 2),
      Text(lbl, style: GoogleFonts.inter(fontSize: 12, color: _textSecondary)),
    ]),
  );

  Widget _vDiv() => Container(width: 1, height: 40, color: _divider);

  // ── More videos ───────────────────────────────────────────────────────────
  Widget _buildMoreVideos() {
    final related = [
      {'title': '${_ex.name} Tutorial',   'dur': '5:30', 'cat': _ex.category},
      {'title': 'Perfect Form Guide',      'dur': '3:45', 'cat': 'Technique'},
      {'title': 'Common Mistakes',         'dur': '4:10', 'cat': 'Tips'},
      {'title': 'Beginner Variation',      'dur': '6:00', 'cat': _ex.category},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _sectionTitle('More Videos'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _VideoCard(
              title: related[i]['title']!,
              duration: related[i]['dur']!,
              category: related[i]['cat']!,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Instructions ──────────────────────────────────────────────────────────
  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 20,
            decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text('How To Do It', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _accent.withAlpha(25), borderRadius: BorderRadius.circular(20)),
            child: Text('✨ AI Powered', style: GoogleFonts.inter(color: _accent, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _card(),
          child: _loadState == _LoadState.loading
              ? _shimmer()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_instructions.length, (i) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: _accent.withAlpha(30), shape: BoxShape.circle),
                          child: Center(child: Text('${i+1}',
                            style: GoogleFonts.inter(color: _accent, fontWeight: FontWeight.bold, fontSize: 14))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_instructions[i],
                          style: GoogleFonts.inter(fontSize: 14, color: _textPrimary, height: 1.5))),
                      ]).animate().fadeIn(delay: (100*i).ms, duration: 300.ms).slideX(begin: 0.05, end: 0),
                      if (i < _instructions.length - 1)
                        const Divider(color: _bg, height: 20),
                    ],
                  )),
                ),
        ),
      ]),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: Colors.grey[200]!,
    highlightColor: Colors.grey[100]!,
    child: Column(mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(height: 14,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7))),
      ))),
  );

  Widget _sectionTitle(String title) => Row(children: [
    Container(width: 4, height: 20,
      decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
    const Spacer(),
    Text('See All', style: GoogleFonts.inter(color: _accent, fontSize: 14)),
  ]);

  // ── Start button ──────────────────────────────────────────────────────────
  Widget _buildStartButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, child) {
          final scale = _loadState == _LoadState.ready
              ? 1.0 + _pulseCtrl.value * 0.02
              : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _startWorkout,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text('Start Exercise',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TIMER OVERLAYS – all using Stack on the Scaffold, fixed constraints
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTimerOverlay() {
    if (_isCompleted) return _buildCompletionOverlay();
    if (_isResting)   return _buildRestOverlay();
    return _buildActiveSetOverlay();
  }

  // ── Active set ────────────────────────────────────────────────────────────
  Widget _buildActiveSetOverlay() {
    final canTap = _currentRep < _repsCount;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Close
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _closeTimer,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: _divider, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: _textSecondary, size: 20),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Exercise name
              Text(_ex.name,
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: _textPrimary),
                textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Set $_currentSet of $_totalSets',
                style: GoogleFonts.inter(color: _textSecondary, fontSize: 16)),
              const SizedBox(height: 36),

              // Rep counter circle
              GestureDetector(
                onTap: canTap ? _nextRep : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: canTap ? _accent : const Color(0xFFE0E0E0), width: 4),
                    color: canTap ? _accent.withOpacity(0.06) : _divider,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$_currentRep',
                      style: GoogleFonts.inter(fontSize: 64, fontWeight: FontWeight.bold,
                        color: canTap ? _accent : _textSecondary)),
                    Text('of $_repsCount reps',
                      style: GoogleFonts.inter(fontSize: 15, color: _textSecondary)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // Set dots progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalSets, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i < _currentSet ? 24 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: i < _currentSet - 1
                        ? Colors.green
                        : i == _currentSet - 1
                            ? _accent
                            : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              const SizedBox(height: 24),

              // Elapsed
              Text('Elapsed: ${_fmt(_totalSecondsElapsed)}',
                style: GoogleFonts.inter(color: _textSecondary, fontSize: 13)),
              const SizedBox(height: 28),

              // Tap button label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: double.infinity, height: 60,
                  decoration: BoxDecoration(
                    color: canTap ? _accent : _accent.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canTap ? [BoxShadow(
                      color: _accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0,4))] : [],
                  ),
                  child: Center(child: Text(
                    _currentRep == 0
                        ? '👆  Tap for each rep'
                        : canTap
                            ? 'Rep $_currentRep ✓  →  Tap next'
                            : 'Set complete!  Resting...',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  )),
                ),
              ),
              const SizedBox(height: 14),

              // Skip set
              TextButton(
                onPressed: _skipSet,
                child: Text('Skip this set →',
                  style: GoogleFonts.inter(color: _textSecondary, fontSize: 14)),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Rest ──────────────────────────────────────────────────────────────────
  Widget _buildRestOverlay() {
    final frac = _restSec > 0 ? _restSecondsRemaining / _restSec : 0.0;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('💤 Rest Time',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
            const SizedBox(height: 8),
            Text(_currentSet < _totalSets
                ? 'Next: Set ${_currentSet + 1} of $_totalSets'
                : 'Last set complete!',
              style: GoogleFonts.inter(color: _textSecondary, fontSize: 16)),
            const SizedBox(height: 50),

            // Circular countdown
            SizedBox(
              width: 160, height: 160,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 160, height: 160,
                  child: CircularProgressIndicator(
                    value: frac.clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: _divider,
                    valueColor: const AlwaysStoppedAnimation(_accent),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_fmt(_restSecondsRemaining),
                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.bold, color: _accent)),
                  Text('remaining', style: GoogleFonts.inter(color: _textSecondary, fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _skipRest,
                  child: Text('Skip Rest →',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _closeTimer,
              child: Text('Stop workout',
                style: GoogleFonts.inter(color: _textSecondary, fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Completion ────────────────────────────────────────────────────────────
  Widget _buildCompletionOverlay() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(color: _accent.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: _accent, size: 56),
            ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
            const SizedBox(height: 24),
            Text('Workout Complete! 🎉',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
            const SizedBox(height: 6),
            Text(_ex.name, style: GoogleFonts.inter(color: _textSecondary, fontSize: 16)),
            const SizedBox(height: 40),

            // Stats
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _cStat(Icons.repeat_rounded,              '$_totalSets',                'Sets'),
              Container(width: 1, height: 40, color: _divider),
              _cStat(Icons.fitness_center_rounded,      '$_repsCount',               'Reps'),
              Container(width: 1, height: 40, color: _divider),
              _cStat(Icons.timer_outlined,              _fmt(_totalSecondsElapsed),  'Duration'),
              Container(width: 1, height: 40, color: _divider),
              _cStat(Icons.local_fire_department_outlined, '${_ex.estimatedCalories}', 'kcal'),
            ]),
            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _elapsedTimer?.cancel();
                    _restTimer?.cancel();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutCompletePage(
                          workoutName: _ex.name,
                          sets: _totalSets,
                          repsCount: _repsCount,
                          caloriesBurned: _ex.estimatedCalories,
                          durationSeconds: _totalSecondsElapsed,
                          // workoutId is null here; WorkoutCompletePage uses logCompletedWorkout
                        ),
                      ),
                    );
                  },
                  child: Text('Done ✓',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () { _closeTimer(); _startWorkout(); },
              child: Text('Do it again',
                style: GoogleFonts.inter(color: _accent, fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _cStat(IconData icon, String val, String lbl) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _accent, size: 22),
      const SizedBox(height: 4),
      Text(val, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
      Text(lbl, style: GoogleFonts.inter(fontSize: 12, color: _textSecondary)),
    ],
  );

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 2))],
  );
}

// ── Video Card (More Videos section) ─────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final String title, duration, category;
  const _VideoCard({required this.title, required this.duration, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Stack(children: [
            Container(
              height: 100, width: 160,
              color: const Color(0xFFF5F5F5),
              child: const Icon(Icons.fitness_center, size: 40, color: Color(0xFFE0E0E0)),
            ),
            Positioned.fill(child: Center(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE8845C).withAlpha(230),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
              ),
            )),
            Positioned(
              bottom: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(179),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(category, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E))),
          ]),
        ),
      ]),
    );
  }
}
