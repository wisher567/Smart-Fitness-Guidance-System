import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitfusion/services/posture_service.dart';
import 'package:fitfusion/screens/posture/widgets/skeleton_painter.dart';

enum _State { selectingExercise, initializing, ready, analyzing, error }

class RealtimePostureScreen extends StatefulWidget {
  const RealtimePostureScreen({super.key});

  @override
  State<RealtimePostureScreen> createState() => _RealtimePostureScreenState();
}

class _RealtimePostureScreenState extends State<RealtimePostureScreen> {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  // ── State ────────────────────────────────────────────────────────────────
  _State _state = _State.selectingExercise;
  String _selectedExercise = 'squat';
  String _errorMessage = '';

  // ── Analysis results ──────────────────────────────────────────────────────
  int _score = 0;
  String _grade = '-';
  List<String> _feedback = [];
  Map<String, dynamic> _angles = {};
  Map<String, LandmarkPoint> _landmarks = {};
  int _fps = 0;
  String _recommendation = '';

  // ── Frame timer ───────────────────────────────────────────────────────────
  Timer? _frameTimer;
  bool _isSendingFrame = false;

  static const _exercises = ['squat', 'pushup', 'plank'];
  static const _exerciseEmojis = {'squat': '🏋️', 'pushup': '💪', 'plank': '🧘'};
  static const _exerciseLabels = {'squat': 'Squat', 'pushup': 'Push Up', 'plank': 'Plank'};

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _stopAnalysis();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Camera setup ──────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    setState(() => _state = _State.initializing);
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _state = _State.error;
          _errorMessage = 'No cameras found on this device.';
        });
        return;
      }
      // Use back camera (index 0)
      final camera = _cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _state = _State.ready);
    } on CameraException catch (e) {
      setState(() {
        _state = _State.error;
        _errorMessage = e.description ?? 'Camera permission denied.';
      });
    } catch (e) {
      setState(() {
        _state = _State.error;
        _errorMessage = e.toString();
      });
    }
  }

  // ── Analysis timer ────────────────────────────────────────────────────────
  void _startAnalysis() {
    setState(() => _state = _State.analyzing);
    _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _sendFrame();
    });
  }

  void _stopAnalysis() {
    _frameTimer?.cancel();
    _frameTimer = null;
    if (mounted && _state == _State.analyzing) {
      setState(() => _state = _State.ready);
    }
  }

  void _toggleAnalysis() {
    if (_state == _State.analyzing) {
      _stopAnalysis();
    } else {
      _startAnalysis();
    }
  }

  Future<void> _sendFrame() async {
    if (_isSendingFrame) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_state != _State.analyzing) return;

    _isSendingFrame = true;
    try {
      // Capture a JPEG frame and read bytes (cross-platform, works on web too)
      final XFile xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Send to backend
      final result = await PostureService.analyzeRealtimeFrame(
        imageBase64: base64Image,
        exercise: _selectedExercise,
      );

      if (mounted && result['detected'] == true) {
        final rawLandmarks =
            result['keyLandmarks'] as Map<String, dynamic>?;
        final newLandmarks = parseLandmarks(rawLandmarks);

        setState(() {
          _score = (result['score'] as num?)?.toInt() ?? _score;
          _grade = result['grade'] as String? ?? _grade;
          _feedback = List<String>.from(result['feedback'] as List? ?? []);
          _angles = Map<String, dynamic>.from(
              result['angles'] as Map? ?? {});
          _recommendation =
              result['recommendation'] as String? ?? _recommendation;
          _landmarks = smoothLandmarks(_landmarks, newLandmarks);
          final ms = (result['processingTimeMs'] as num?)?.toInt() ?? 500;
          _fps = ms > 0 ? (1000 / ms).round() : 0;
        });
      } else if (mounted && result['detected'] == false) {
        // Clear skeleton when no person detected
        setState(() => _landmarks = {});
      }
    } catch (e) {
      // Silently skip bad frames — don't show error per frame
      debugPrint('Frame error: $e');
    } finally {
      _isSendingFrame = false;
    }
  }

  // ── Score color ───────────────────────────────────────────────────────────
  Color _scoreColor(int s) {
    if (s >= 90) return const Color(0xFF00E676);
    if (s >= 75) return const Color(0xFF69F0AE);
    if (s >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  // ── Angle color for sidebar ───────────────────────────────────────────────
  Color _angleColor(String key, double value) {
    if (key.contains('Knee') || key.contains('knee')) {
      if (value >= 80 && value <= 120) return const Color(0xFF00E676);
      return const Color(0xFFFF9800);
    }
    if (key.contains('back') || key.contains('Back') || key.contains('Body')) {
      return value >= 160 ? const Color(0xFF00E676) : const Color(0xFFFF9800);
    }
    if (key.contains('Elbow') || key.contains('elbow')) {
      if (value >= 60 && value <= 120) return const Color(0xFF00E676);
      return const Color(0xFFFF9800);
    }
    return Colors.white;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_state == _State.initializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E676)),
            SizedBox(height: 16),
            Text('Starting camera…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_state == _State.error) {
      return _buildErrorState();
    }

    if (_state == _State.selectingExercise) {
      return _buildExerciseSelectState();
    }

    // Camera states: ready / analyzing / paused
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Camera feed
        if (_cameraController != null &&
            _cameraController!.value.isInitialized)
          CameraPreview(_cameraController!),

        // Layer 2: Skeleton overlay
        if (_landmarks.isNotEmpty)
          CustomPaint(
            painter: SkeletonPainter(landmarks: _landmarks),
          ),

        // Layer 3: Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(),
        ),

        // Layer 5: Right-side angle panel
        if (_angles.isNotEmpty && _state == _State.analyzing)
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(child: _buildAnglePanel()),
          ),

        // Layer 4: Bottom score card + start/stop button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStartStopButton(),
              if (_state == _State.analyzing) _buildBottomScoreCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_rounded,
              color: Color(0xFFF44336), size: 64),
          const SizedBox(height: 16),
          Text('Camera Error',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(_errorMessage,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _initCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(14)),
              child: Text('Retry',
                  style: GoogleFonts.poppins(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back',
                style: GoogleFonts.poppins(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // ── Exercise selection (initial state) ────────────────────────────────────
  Widget _buildExerciseSelectState() {
    return SafeArea(
      child: Column(
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Live Detection',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          Text('Choose Exercise',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Select before starting live analysis',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 32),
          ..._exercises.map((ex) {
            final isSelected = ex == _selectedExercise;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedExercise = ex),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00E676).withAlpha(28)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : const Color(0xFF333333),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_exerciseEmojis[ex]!,
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Text(_exerciseLabels[ex]!,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00E676), size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: GestureDetector(
              onTap: () => setState(() => _state = _State.ready),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF1DB954)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text('Start Camera 🎥',
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        color: Colors.black.withAlpha(140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _stopAnalysis();
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_exerciseEmojis[_selectedExercise]} ${_exerciseLabels[_selectedExercise]}',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Spacer(),
                if (_fps > 0)
                  Text('$_fps FPS',
                      style: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 11)),
              ],
            ),
            // Exercise selector chips (always visible)
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _exercises.map((ex) {
                final selected = ex == _selectedExercise;
                return GestureDetector(
                  onTap: () {
                    if (_state == _State.analyzing) _stopAnalysis();
                    setState(() {
                      _selectedExercise = ex;
                      _landmarks = {};
                      _score = 0;
                      _grade = '-';
                      _feedback = [];
                      _angles = {};
                    });
                  },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF00E676)
                          : Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_exerciseEmojis[ex]} ${_exerciseLabels[ex]}',
                      style: GoogleFonts.poppins(
                        color: selected ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Start/Stop button ─────────────────────────────────────────────────────
  Widget _buildStartStopButton() {
    final isAnalyzing = _state == _State.analyzing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: _toggleAnalysis,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: isAnalyzing
                ? const LinearGradient(
                    colors: [Color(0xFFF44336), Color(0xFFD32F2F)])
                : const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF1DB954)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isAnalyzing
                        ? const Color(0xFFF44336)
                        : const Color(0xFF00E676))
                    .withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAnalyzing
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isAnalyzing ? 'Stop Analysis' : '🟢 Start Analysis',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom score card ─────────────────────────────────────────────────────
  Widget _buildBottomScoreCard() {
    final color = _scoreColor(_score);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(204),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score + grade + progress bar row
          Row(
            children: [
              // Score number
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_score',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: '/100',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Progress bar + grade
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: 600.ms,
                      height: 6,
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(3)),
                      child: LayoutBuilder(builder: (ctx, constraints) {
                        return Stack(children: [
                          AnimatedContainer(
                            duration: 600.ms,
                            width:
                                constraints.maxWidth * (_score / 100),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ]);
                      }),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(38),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: color.withAlpha(100)),
                          ),
                          child: Text(
                            'Grade $_grade',
                            style: GoogleFonts.poppins(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Feedback chips
          if (_feedback.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _feedback.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final item = _feedback[i];
                  Color chipColor = const Color(0xFF00E676);
                  if (item.startsWith('⚠️')) chipColor = const Color(0xFFFF9800);
                  if (item.startsWith('❌')) chipColor = const Color(0xFFF44336);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: chipColor.withAlpha(150), width: 1),
                    ),
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
          // Recommendation
          if (_recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _recommendation,
              style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ).animate().slideY(begin: 0.05, end: 0, duration: 300.ms);
  }

  // ── Side angle panel ──────────────────────────────────────────────────────
  Widget _buildAnglePanel() {
    final angleEntries = _angles.entries.take(3).toList();
    if (angleEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: angleEntries.map((e) {
        final value = (e.value as num?)?.toDouble() ?? 0;
        final color = _angleColor(e.key, value);
        final label = e.key
            .replaceAllMapped(
                RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
            .trim();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(153),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label.length > 10
                    ? '${label.substring(0, 9)}.'
                    : label,
                style: GoogleFonts.poppins(
                    color: Colors.grey, fontSize: 9),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                '${value.toStringAsFixed(0)}°',
                style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
