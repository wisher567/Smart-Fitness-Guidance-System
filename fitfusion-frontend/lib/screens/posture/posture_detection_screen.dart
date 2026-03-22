import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fitfusion/providers/posture_provider.dart';
import 'package:fitfusion/screens/posture/posture_result_screen.dart';
import 'package:fitfusion/screens/posture/realtime_posture_screen.dart';
import 'package:fitfusion/screens/posture/widgets/exercise_selector.dart';

class PostureDetectionScreen extends StatefulWidget {
  const PostureDetectionScreen({super.key});
  @override
  State<PostureDetectionScreen> createState() => _PostureDetectionScreenState();
}

class _PostureDetectionScreenState extends State<PostureDetectionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Theme helpers (matching HydrationScreen / home_page pattern) ───────────
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
  Color get cardColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  static const Color primaryColor = Color(0xFFFE7235); // FitFusion orange
  Color get textPrimary => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.white54 : Colors.black54;
  Color get borderColor => isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
  Color get surfaceColor => isDark ? const Color(0xFF2A2A2D) : const Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostureProvider>().loadExercises();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final xf = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (xf != null && mounted) {
        context.read<PostureProvider>().setImage(File(xf.path));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e',
          isError: true,
        );
      }
    }
  }

  // ── Analyze ────────────────────────────────────────────────────────────────
  Future<void> _analyze() async {
    final provider = context.read<PostureProvider>();

    if (provider.selectedExercise == null) {
      _showSnackBar('Please select an exercise first 👆');
      return;
    }
    if (provider.selectedImage == null) {
      _showSnackBar('Please take or upload a photo 📸');
      return;
    }

    final result = await provider.analyze();
    if (!mounted) return;

    if (result != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostureResultScreen(
            analysisResult: result,
            exerciseName: provider.selectedExercise!,
            imageFile: provider.selectedImage!,
          ),
        ),
      );
    } else {
      final err = provider.error ?? 'Analysis failed';
      _showSnackBar(_friendlyError(err), isError: true, showRetry: true);
    }
  }

  String _friendlyError(String err) {
    if (err.contains('person') || err.contains('No person')) {
      return '🚫 No person detected. Make sure your full body is visible.';
    }
    if (err.contains('timeout') || err.contains('SocketException') ||
        err.contains('Connection')) {
      return '📡 Connection failed. Is the FitFusion server running?';
    }
    if (err.contains('8000') || err.contains('AI') || err.contains('Python')) {
      return '🤖 AI service is offline. Check the Python service.';
    }
    return '⚠️ $err';
  }

  void _showSnackBar(String msg,
      {bool isError = false, bool showRetry = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: showRetry
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _analyze,
              )
            : null,
      ),
    );
  }

  // ── How-to sheet ───────────────────────────────────────────────────────────
  void _showHowToBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _HowToBottomSheet(
        cardColor: cardColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryColor: primaryColor,
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
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
            'Posture Detection',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline, color: textSecondary),
              onPressed: _showHowToBottomSheet,
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Mode cards ──────────────────────────────────────────────
              _buildModeCards(),
              const SizedBox(height: 28),

              // ── Exercise selector ───────────────────────────────────────
              Text('Select Exercise',
                  style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildExerciseSelector(),
              const SizedBox(height: 24),

              // ── Image section ───────────────────────────────────────────
              Text('Your Photo',
                  style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildImageSection(screenHeight),
              const SizedBox(height: 20),

              // ── Tips ────────────────────────────────────────────────────
              _buildTipsSection(),
              const SizedBox(height: 24),

              // ── Analyze button ──────────────────────────────────────────
              _buildAnalyzeButton(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── Mode cards (Photo vs Live) ─────────────────────────────────────────────
  Widget _buildModeCards() {
    return Row(
      children: [
        // Photo Mode (current) – orange outlined
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.camera_alt_rounded, color: primaryColor, size: 26),
              const SizedBox(height: 8),
              Text('Photo Mode',
                  style: GoogleFonts.poppins(
                      color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('Take a photo\nfor deep analysis',
                  style: GoogleFonts.poppins(
                      color: textSecondary, fontSize: 11, height: 1.3)),
              const SizedBox(height: 6),
              Text('Best for beginners',
                  style: GoogleFonts.poppins(
                      color: primaryColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        // Live Mode – surface card with orange NEW badge
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RealtimePostureScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Stack(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.videocam_rounded, color: primaryColor, size: 26),
                    const SizedBox(height: 8),
                    Text('Live Mode',
                        style: GoogleFonts.poppins(
                            color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text('Real-time feedback\nwhile you workout',
                        style: GoogleFonts.poppins(
                            color: textSecondary, fontSize: 11, height: 1.3)),
                    const SizedBox(height: 6),
                    Text('Active workouts',
                        style: GoogleFonts.poppins(
                            color: primaryColor, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('★ NEW',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  // ── Exercise selector ──────────────────────────────────────────────────────
  Widget _buildExerciseSelector() {
    return Consumer<PostureProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return _buildExerciseShimmer();
        }
        return ExerciseSelector(
          exercises: provider.exercises,
          selectedExercise: provider.selectedExercise,
          isLoading: false,
          onSelect: (id) => provider.selectExercise(id),
          primaryColor: primaryColor,
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildExerciseShimmer() {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            3,
            (_) => Container(
              width: 100,
              height: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Image section ──────────────────────────────────────────────────────────
  Widget _buildImageSection(double screenHeight) {
    return Consumer<PostureProvider>(
      builder: (context, provider, _) {
        final hasImage = provider.selectedImage != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: screenHeight * 0.34,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasImage ? primaryColor : borderColor,
              width: hasImage ? 2.0 : 1.0,
            ),
            boxShadow: isDark
                ? []
                : [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          clipBehavior: Clip.hardEdge,
          child: hasImage
              ? _imagePreview(provider)
              : _emptyImageState(),
        );
      },
    );
  }

  Widget _emptyImageState() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _pulseAnimation.value, child: child),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.camera_alt_rounded, color: primaryColor, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            'Position yourself in frame',
            style: GoogleFonts.poppins(
                color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure your full body is visible',
            style: GoogleFonts.poppins(color: textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _imageButton(
                    label: '📸 Camera',
                    isPrimary: true,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _imageButton(
                    label: '🖼️ Gallery',
                    isPrimary: false,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? primaryColor : borderColor,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isPrimary ? Colors.white : textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePreview(PostureProvider provider) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(provider.selectedImage!, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withAlpha(178), Colors.transparent],
              stops: const [0, 0.5],
            ),
          ),
        ),
        Positioned(
          bottom: 14,
          left: 14,
          right: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✅ Photo ready',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => provider.clearImage(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, color: Colors.white, size: 15),
                      const SizedBox(width: 4),
                      Text('Retake',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tips ───────────────────────────────────────────────────────────────────
  Widget _buildTipsSection() {
    return Consumer<PostureProvider>(builder: (context, provider, _) {
      final tips = _getTips(provider.selectedExercise ?? '');
      if (tips.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Tips',
              style: GoogleFonts.poppins(
                  color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: tips.asMap().entries.map((entry) {
                final i = entry.key;
                final tip = entry.value;
                return Padding(
                  padding: EdgeInsets.only(right: i < tips.length - 1 ? 12 : 0),
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                          left: BorderSide(color: primaryColor, width: 3)),
                      boxShadow: isDark
                          ? []
                          : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(tip['icon']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(tip['title']!,
                                style: GoogleFonts.poppins(
                                    color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(tip['body']!,
                            style: GoogleFonts.poppins(
                                color: textSecondary, fontSize: 11, height: 1.3)),
                      ],
                    ),
                  ).animate().fadeIn(delay: (i * 80).ms),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  // ── Analyze button ─────────────────────────────────────────────────────────
  Widget _buildAnalyzeButton() {
    return Consumer<PostureProvider>(builder: (context, provider, _) {
      final canAnalyze = provider.canAnalyze;
      final isAnalyzing = provider.isAnalyzing;

      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(
          scale: canAnalyze && !isAnalyzing ? _pulseAnimation.value : 1.0,
          child: child,
        ),
        child: GestureDetector(
          onTap: (canAnalyze && !isAnalyzing) ? _analyze : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56,
            decoration: BoxDecoration(
              color: canAnalyze ? primaryColor : surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: canAnalyze
                  ? [
                      BoxShadow(
                        color: primaryColor.withAlpha(76),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: isAnalyzing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text('Analyzing your form…',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    )
                  : Text(
                      canAnalyze ? 'Analyze My Form 🤖' : 'Select exercise & photo first',
                      style: GoogleFonts.poppins(
                        color: canAnalyze ? Colors.white : textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<Map<String, String>> _getTips(String exercise) {
    final lower = exercise.toLowerCase();
    if (lower.contains('squat')) {
      return [
        {'icon': '👀', 'title': 'Look forward', 'body': 'Keep eyes level, don\'t look down'},
        {'icon': '🦵', 'title': 'Knee alignment', 'body': 'Knees should track over toes'},
        {'icon': '🔙', 'title': 'Straight back', 'body': 'Chest up, slight forward lean is ok'},
      ];
    } else if (lower.contains('push')) {
      return [
        {'icon': '💪', 'title': 'Full range', 'body': 'Lower chest to just above ground'},
        {'icon': '🏋️', 'title': 'Core tight', 'body': 'Engage abs throughout'},
        {'icon': '👐', 'title': 'Hand width', 'body': 'Slightly wider than shoulders'},
      ];
    } else if (lower.contains('plank')) {
      return [
        {'icon': '📐', 'title': 'Straight line', 'body': 'Head to heels aligned'},
        {'icon': '🌬️', 'title': 'Breathe steady', 'body': 'Don\'t hold your breath'},
        {'icon': '👀', 'title': 'Neutral neck', 'body': 'Look at floor, not forward'},
      ];
    }
    return [];
  }
}

// ── Exercise Selector (updated to accept theme params) ─────────────────────
// Note: ExerciseSelector widget is in its own file, we pass theme params via constructor

// ── How-To Bottom Sheet ────────────────────────────────────────────────────
class _HowToBottomSheet extends StatelessWidget {
  final Color cardColor, textPrimary, textSecondary, primaryColor;
  const _HowToBottomSheet({
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
  });

  static const _steps = [
    {'icon': '🤸', 'step': 'Step 1', 'text': 'Select your exercise'},
    {'icon': '📸', 'step': 'Step 2', 'text': 'Take a photo or pick from gallery'},
    {'icon': '🤖', 'step': 'Step 3', 'text': 'AI analyzes your form instantly'},
    {'icon': '📊', 'step': 'Step 4', 'text': 'Get score and improvement tips'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('How to use Posture Detection',
              style: GoogleFonts.poppins(
                  color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ..._steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(s['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['step']!,
                          style: GoogleFonts.poppins(
                              color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(s['text']!,
                          style: GoogleFonts.poppins(color: textPrimary, fontSize: 14)),
                    ]),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Got it!',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
