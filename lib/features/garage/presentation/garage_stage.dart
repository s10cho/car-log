import 'package:flutter/material.dart';

import '../domain/care_score.dart';
import '../domain/car_body_style.dart';
import 'car_scene.dart';
import 'care_score_ring.dart';

/// The car on its stage at the top of the home screen.
///
/// The backdrop reacts to the care score: a clear day when everything is in
/// order, a warmer, heavier sky when something is overdue. It is the one place
/// the app says how things are before the user reads a single number.
class GarageStage extends StatelessWidget {
  const GarageStage({
    required this.style,
    required this.score,
    this.height = 190,
    super.key,
  });

  final CarBodyStyle style;
  final CareScore score;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = score.isUnrated
        ? scheme.surfaceContainerHighest
        : gradeColour(scheme, score.grade);

    // A car in good order rolls; one that needs attention sits still.
    final pose = score.isUnrated || score.overdue > 0
        ? CarPose.parked
        : CarPose.driving;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [accent.withValues(alpha: 0.22), scheme.surface],
        ),
      ),
      child: Stack(
        children: [
          // The ground the car stands on, so it reads as a place.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surfaceContainerHighest.withValues(alpha: 0),
                    scheme.surfaceContainerHighest,
                  ],
                ),
              ),
            ),
          ),
          // The car keeps to the left so it can never collide with the
          // score ring, and is centred within that space rather than the card.
          Align(
            alignment: Alignment.bottomLeft,
            child: FractionallySizedBox(
              widthFactor: 0.72,
              child: CarScene(style: style, pose: pose, height: height - 12),
            ),
          ),
          // The score rides on the stage rather than below it, so the first
          // screenful answers "is my car fine?" without scrolling.
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CareScoreRing(score: score, size: 92),
                const SizedBox(height: 2),
                Text(
                  score.isUnrated ? '' : score.grade.label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
