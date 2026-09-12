import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/care_score.dart';

/// The care score as a ring that fills.
///
/// A number alone reads as a grade; a ring that fills reads as progress, which
/// is the feeling that brings someone back to close the gap.
class CareScoreRing extends StatelessWidget {
  const CareScoreRing({required this.score, this.size = 132, super.key});

  final CareScore score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = gradeColour(theme.colorScheme, score.grade);

    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: score.isUnrated ? 0 : score.value / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => CustomPaint(
          painter: _RingPainter(
            progress: progress,
            colour: colour,
            track: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (score.isUnrated)
                  Icon(Icons.help_outline, color: theme.colorScheme.outline)
                else
                  Text(
                    '${(progress * 100).round()}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colour,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  score.isUnrated ? '기록 없음' : '관리 점수',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Colour for a grade, so wording and ring always agree.
Color gradeColour(ColorScheme scheme, CareGrade grade) => switch (grade) {
  CareGrade.excellent => scheme.primary,
  CareGrade.good => scheme.secondary,
  CareGrade.attention => scheme.tertiary,
  CareGrade.urgent => scheme.error,
};

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.colour,
    required this.track,
  });

  final double progress;
  final Color colour;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - stroke) / 2,
    );

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    if (progress <= 0) {
      return;
    }
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      base..color = colour,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colour != colour;
}
