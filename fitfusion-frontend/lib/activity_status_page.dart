import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitfusion/providers/workout_provider.dart';
import 'sports_location_map_page.dart';

class ActivityStatusPage extends StatefulWidget {
  const ActivityStatusPage({super.key});

  @override
  State<ActivityStatusPage> createState() => _ActivityStatusPageState();
}

class _ActivityStatusPageState extends State<ActivityStatusPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  // Theme Helpers
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get bgColor => isDark ? const Color(0xFF121212) : Colors.white;
  Color get textPrimary => isDark ? Colors.white : Colors.black;
  Color get textSecondary => isDark ? Colors.white70 : Colors.black87;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 4)
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Map<String, int> _aggregateWorkouts(List<dynamic> history) {
    // Map of type to total minutes
    final Map<String, int> totals = {
      'Running': 0,
      'Jogging': 0,
      'Biking': 0,
      'Weightlifting': 0,
      'Yoga': 0,
    };

    int totalMins = 0;

    for (var workout in history) {
      String type = workout['type']?.toString() ?? 'Other';
      int mins = (workout['duration'] is num) ? (workout['duration'] as num).toInt() : 30;
      
      // Map 'Cardio' or others to known types if needed, else ignore
      if (totals.containsKey(type)) {
        totals[type] = totals[type]! + mins;
      } else if (type.toLowerCase().contains('run')) {
        totals['Running'] = totals['Running']! + mins;
      } else if (type.toLowerCase().contains('lift') || type.toLowerCase().contains('strength')) {
        totals['Weightlifting'] = totals['Weightlifting']! + mins;
      } else {
        // Just add to jogging as fallback for visual filler
        totals['Jogging'] = totals['Jogging']! + mins;
      }
      totalMins += mins;
    }

    totals['Total'] = totalMins;
    return totals;
  }

  String _formatTime(int minutes) {
    if (minutes == 0) return '0h';
    if (minutes < 60) return '${minutes}m';
    int hours = minutes ~/ 60;
    return '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF333333) : Colors.grey.withAlpha(102)),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Activity Status",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                    ),
                  ),
                  const SizedBox(width: 44), // Balance the row
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem(const Color(0xFF2A2A2A), "Running"),
                      const SizedBox(width: 16),
                      _legendItem(const Color(0xFFF97316), "Jogging"),
                      const SizedBox(width: 16),
                      _legendItem(const Color(0xFFEF4444), "Biking"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem(const Color(0xFF3B82F6), "Weightlift"),
                      const SizedBox(width: 16),
                      _legendItem(const Color(0xFFD1D5DB), "Yoga", isDarkTxt: true),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ),

            const SizedBox(height: 30),

            // Content Area
            Expanded(
              child: provider.isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFE7235)))
                : provider.error != null
                  ? Center(child: Text(provider.error!, style: TextStyle(color: Colors.red)))
                  : _buildActivityCanvas(provider.workoutHistory, size),
            ),

            // Continue Button showing summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE7235), // Brand Orange
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFFFE7235).withAlpha(100),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SportsLocationMapPage(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        provider.workoutHistory.isEmpty 
                            ? "Start First Activity" 
                            : "View Gym Locations",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.map_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ).animate().slideY(begin: 1.0, end: 0.0, curve: Curves.easeOutBack, duration: 600.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text, {bool isDarkTxt = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCanvas(List<dynamic> history, Size size) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run, size: 80, color: Colors.grey.withAlpha(70)),
            const SizedBox(height: 16),
            Text(
              "No recent activities",
              style: GoogleFonts.poppins(color: textSecondary, fontSize: 18),
            )
          ],
        ).animate().fadeIn(),
      );
    }

    final totals = _aggregateWorkouts(history);
    
    // Calculate responsive sizes and positions
    final double centerX = size.width / 2;
    final double centerY = (size.height - 350) / 2; // Approximate available height
    
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Background decorative circle
          Positioned(
            left: centerX - 150,
            top: centerY - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
              ),
            ),
          ),
          
          // Biking (Red) - Top Left
          _buildFloatingCard(
            totals['Biking'] ?? 0,
            const Color(0xFFEF4444),
            centerX - 120,
            centerY - 130,
            -0.15,
            size.width * 0.28,
            animationFactor: 1.0,
          ),
          
          // Yoga (Grey) - Bottom Left
          _buildFloatingCard(
            totals['Yoga'] ?? 0,
            isDark ? const Color(0xFF444444) : const Color(0xFFEEEEEE),
            centerX - 130,
            centerY + 40,
            -0.1,
            size.width * 0.32,
            isDarkTxt: !isDark,
            animationFactor: 0.7,
            delay: 100,
          ),
          
          // Jogging (Orange) - Top Right
          _buildFloatingCard(
            totals['Jogging'] ?? 0,
            const Color(0xFFF97316),
            centerX + 40,
            centerY - 120,
            0.18,
            size.width * 0.28,
            animationFactor: 1.2,
            delay: 200,
          ),
          
          // Weightlifting (Blue) - Bottom Right
          _buildFloatingCard(
            totals['Weightlifting'] ?? 0,
            const Color(0xFF3B82F6),
            centerX + 30,
            centerY + 30,
            0.12,
            size.width * 0.3,
            animationFactor: 0.9,
            delay: 300,
          ),
          
          // Total/Running (Black/White) - Center Top Layer
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final val = sin(_animController.value * 2 * pi) * 10;
              return Positioned(
                left: centerX - (size.width * 0.45) / 2,
                top: centerY - 60 + val * 0.5,
                child: child!,
              );
            },
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                width: size.width * 0.45,
                height: size.width * 0.35,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(totals['Total'] ?? 0),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: size.width > 350 ? 52 : 42,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      "Total Activity",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().scaleXY(begin: 0.0, end: 1.0, curve: Curves.easeOutBack, duration: 800.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard(
    int minutes,
    Color color,
    double left,
    double top,
    double angle,
    double size,
    {bool isDarkTxt = false, double animationFactor = 1.0, int delay = 0}
  ) {
    if (minutes == 0 && delay > 0) {
      // Still show empty bubble as layout placeholder
    }
    
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        // Floating effect
        final verticalOffset = sin((_animController.value * 2 * pi) + delay) * (15 * animationFactor);
        return Positioned(
          left: left,
          top: top + verticalOffset,
          child: child!,
        );
      },
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size * 0.85,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(70),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                minutes > 0 ? _formatTime(minutes) : "0h",
                style: GoogleFonts.inter(
                  color: isDarkTxt ? const Color(0xFF333333) : Colors.white,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: delay.ms).scaleXY(begin: 0.0, end: 1.0, curve: Curves.easeOutBack, duration: 600.ms),
    );
  }
}
