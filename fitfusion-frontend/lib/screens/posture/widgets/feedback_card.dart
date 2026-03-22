import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FeedbackCard extends StatelessWidget {
  final List<String> feedbackItems;

  const FeedbackCard({super.key, required this.feedbackItems});

  Color _borderColor(String item) {
    if (item.startsWith('✅')) return const Color(0xFF00E676);
    if (item.startsWith('⚠️')) return const Color(0xFFFF9800);
    if (item.startsWith('❌')) return const Color(0xFFF44336);
    if (item.startsWith('⬇️')) return const Color(0xFF2196F3);
    return const Color(0xFF00E676);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: feedbackItems.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FeedbackItem(
            text: item,
            borderColor: _borderColor(item),
            index: i,
          ),
        );
      }).toList(),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  final String text;
  final Color borderColor;
  final int index;

  const _FeedbackItem({
    required this.text,
    required this.borderColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 350.ms, delay: (100 + index * 100).ms),
        SlideEffect(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
          duration: 350.ms,
          delay: (100 + index * 100).ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
