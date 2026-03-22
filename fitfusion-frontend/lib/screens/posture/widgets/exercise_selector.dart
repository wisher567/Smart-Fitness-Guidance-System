import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExerciseSelector extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final String? selectedExercise;
  final bool isLoading;
  final ValueChanged<String> onSelect;

  // Theme params (injected by parent to keep this widget theme-aware)
  final Color primaryColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final bool isDark;

  const ExerciseSelector({
    super.key,
    required this.exercises,
    required this.selectedExercise,
    required this.isLoading,
    required this.onSelect,
    this.primaryColor = const Color(0xFFFE7235),
    this.cardColor = Colors.white,
    this.textPrimary = Colors.black87,
    this.textSecondary = Colors.black54,
    this.borderColor = const Color(0xFFE0E0E0),
    this.isDark = false,
  });

  @override
  State<ExerciseSelector> createState() => _ExerciseSelectorState();
}

class _ExerciseSelectorState extends State<ExerciseSelector> {
  final Map<int, bool> _tapping = {};

  String _emoji(Map<String, dynamic> e) {
    final name = (e['name'] as String? ?? '').toLowerCase();
    final emoji = e['emoji'] as String?;
    if (emoji != null && emoji.isNotEmpty) return emoji;
    if (name.contains('squat')) return '🏋️';
    if (name.contains('push')) return '💪';
    if (name.contains('plank')) return '🧘';
    return '🏃';
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.exercises;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: exercises.asMap().entries.map((entry) {
          final idx = entry.key;
          final ex = entry.value;
          final id = ex['id'] as String? ?? ex['name'] as String? ?? '';
          final name = ex['name'] as String? ?? id;
          final isSelected = widget.selectedExercise == id;
          final available = ex['available'] as bool? ?? true;

          return Padding(
            padding: EdgeInsets.only(right: idx < exercises.length - 1 ? 12 : 0),
            child: GestureDetector(
              onTapDown: available
                  ? (_) => setState(() => _tapping[idx] = true)
                  : null,
              onTapUp: available
                  ? (_) {
                      setState(() => _tapping[idx] = false);
                      widget.onSelect(id);
                    }
                  : null,
              onTapCancel: available
                  ? () => setState(() => _tapping[idx] = false)
                  : null,
              child: AnimatedScale(
                scale: (_tapping[idx] == true) ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: _ExerciseCard(
                  name: name,
                  emoji: _emoji(ex),
                  isSelected: isSelected,
                  available: available,
                  index: idx,
                  primaryColor: widget.primaryColor,
                  cardColor: widget.cardColor,
                  textPrimary: widget.textPrimary,
                  textSecondary: widget.textSecondary,
                  borderColor: widget.borderColor,
                  isDark: widget.isDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Exercise Card ─────────────────────────────────────────────────────────────
class _ExerciseCard extends StatelessWidget {
  final String name;
  final String emoji;
  final bool isSelected;
  final bool available;
  final int index;
  final Color primaryColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final bool isDark;

  const _ExerciseCard({
    required this.name,
    required this.emoji,
    required this.isSelected,
    required this.available,
    required this.index,
    required this.primaryColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 300.ms, delay: (index * 60).ms),
        SlideEffect(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
          duration: 300.ms,
          delay: (index * 60).ms,
        ),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 110,
            height: 120,
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withAlpha(22)
                  : cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryColor : borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(isSelected ? 18 : 8),
                        blurRadius: isSelected ? 10 : 4,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: available
                        ? (isSelected ? primaryColor : textPrimary)
                        : textSecondary,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                if (!available) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Soon',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Orange checkmark badge when selected
          if (isSelected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
