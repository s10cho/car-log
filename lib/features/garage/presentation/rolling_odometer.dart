import 'package:flutter/material.dart';

import '../../../core/formatting/app_formats.dart';

/// The odometer, counting up to its value.
///
/// A number that lands instantly is a label; a number that rolls up is the
/// dial on a dashboard. The same information, read with more interest.
class RollingOdometer extends StatelessWidget {
  const RollingOdometer({required this.kilometres, this.style, super.key});

  final int kilometres;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // `begin` only applies to the first build, where it gives the dial its
      // wind-up. Later changes animate from whatever is on screen, so a
      // correction of 500 km rolls 500 km rather than starting over at zero.
      tween: Tween(begin: 0, end: kilometres.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        formatKilometres(value.round()),
        style: style ?? Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
