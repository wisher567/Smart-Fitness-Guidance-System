import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AngleDisplay extends StatelessWidget {
  final Map<String, dynamic> angles;
  final String exercise;

  const AngleDisplay({
    super.key,
    required this.angles,
    required this.exercise,
  });

  List<_AngleItem> _getAngles() {
    final ex = exercise.toLowerCase();

    if (ex.contains('squat')) {
      return [
        _AngleItem(
          label: 'Left Knee',
          value: (angles['leftKnee'] as num?)?.toDouble() ?? 0,
          exercise: 'squat_knee',
        ),
        _AngleItem(
          label: 'Right Knee',
          value: (angles['rightKnee'] as num?)?.toDouble() ?? 0,
          exercise: 'squat_knee',
        ),
        _AngleItem(
          label: 'Back Angle',
          value: (angles['backAngle'] as num?)?.toDouble() ?? 0,
          exercise: 'back',
        ),
      ];
    } else if (ex.contains('push')) {
      return [
        _AngleItem(
          label: 'Left Elbow',
          value: (angles['leftElbow'] as num?)?.toDouble() ?? 0,
          exercise: 'elbow',
        ),
        _AngleItem(
          label: 'Right Elbow',
          value: (angles['rightElbow'] as num?)?.toDouble() ?? 0,
          exercise: 'elbow',
        ),
        _AngleItem(
          label: 'Body Alignment',
          value: (angles['bodyAlignment'] as num?)?.toDouble() ?? 0,
          exercise: 'body_align',
        ),
      ];
    } else if (ex.contains('plank')) {
      return [
        _AngleItem(
          label: 'Body Angle',
          value: (angles['bodyAngle'] as num?)?.toDouble() ?? 0,
          exercise: 'body_align',
        ),
        _AngleItem(
          label: 'Hip Angle',
          value: (angles['hipAngle'] as num?)?.toDouble() ?? 0,
          exercise: 'body_align',
        ),
        _AngleItem(
          label: 'Neck Angle',
          value: (angles['neckAngle'] as num?)?.toDouble() ?? 0,
          exercise: 'back',
        ),
      ];
    }

    // Fallback: show whatever angles are in the map
    final items = <_AngleItem>[];
    angles.forEach((key, value) {
      if (items.length < 3) {
        items.add(_AngleItem(
          label: _formatLabel(key),
          value: (value as num?)?.toDouble() ?? 0,
          exercise: 'default',
        ));
      }
    });
    return items;
  }

  String _formatLabel(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)}',
        )
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : w)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final items = _getAngles();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return SizedBox(
          width: cardWidth,
          child: _AngleCard(item: item, index: i),
        );
      }).toList(),
    );
  }
}

class _AngleItem {
  final String label;
  final double value;
  final String exercise;

  const _AngleItem({
    required this.label,
    required this.value,
    required this.exercise,
  });

  ({Color color, String statusText}) get status {
    if (exercise == 'squat_knee') {
      if (value >= 80 && value <= 100) {
        return (color: const Color(0xFF00E676), statusText: '✅ Ideal');
      } else if (value > 100 && value <= 120) {
        return (color: const Color(0xFFFF9800), statusText: '🟡 OK');
      } else if (value > 120) {
        return (color: const Color(0xFFF44336), statusText: '🔴 Shallow');
      } else {
        return (color: const Color(0xFFFF9800), statusText: '🟡 Deep');
      }
    } else if (exercise == 'back') {
      if (value >= 160) {
        return (color: const Color(0xFF00E676), statusText: '✅ Upright');
      } else if (value >= 140) {
        return (color: const Color(0xFFFF9800), statusText: '🟡 Slight lean');
      } else {
        return (color: const Color(0xFFF44336), statusText: '🔴 Too forward');
      }
    } else if (exercise == 'elbow') {
      if (value >= 60 && value <= 90) {
        return (color: const Color(0xFF00E676), statusText: '✅ Good depth');
      } else if (value > 90 && value <= 120) {
        return (color: const Color(0xFFFF9800), statusText: '🟡 OK');
      } else {
        return (color: const Color(0xFFF44336), statusText: '🔴 Too high');
      }
    } else if (exercise == 'body_align') {
      if (value >= 165) {
        return (color: const Color(0xFF00E676), statusText: '✅ Straight');
      } else {
        return (color: const Color(0xFFF44336), statusText: '🔴 Hip issues');
      }
    }
    return (color: const Color(0xFF00E676), statusText: '✅ OK');
  }
}

class _AngleCard extends StatefulWidget {
  final _AngleItem item;
  final int index;

  const _AngleCard({required this.item, required this.index});

  @override
  State<_AngleCard> createState() => _AngleCardState();
}

class _AngleCardState extends State<_AngleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: widget.item.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: 200 + widget.index * 150), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.item.status;

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, delay: (200 + widget.index * 150).ms),
        SlideEffect(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
          duration: 400.ms,
          delay: (200 + widget.index * 150).ms,
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.item.label,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _animation.value.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: '°',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: st.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    st.statusText,
                    style: GoogleFonts.poppins(
                      color: st.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
