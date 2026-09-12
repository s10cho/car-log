import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The frame every wizard step sits in.
///
/// One question on screen at a time. A long form asks the user to plan their
/// answers; a single question asks them to answer it, and the ones already
/// answered stay visible as chips so nothing feels lost.
class WizardStepScaffold extends StatelessWidget {
  const WizardStepScaffold({
    required this.title,
    required this.stepIndex,
    required this.stepCount,
    required this.child,
    this.subtitle,
    this.answered = const [],
    this.onBack,
    this.footer,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Zero-based.
  final int stepIndex;
  final int stepCount;

  /// Short summaries of earlier answers, newest last.
  final List<String> answered;

  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepProgress(stepIndex: stepIndex, stepCount: stepCount),
        const SizedBox(height: 20),
        if (answered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final answer in answered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(answer, style: theme.textTheme.labelMedium),
                  ),
              ],
            ),
          ),
        Text(title, style: theme.textTheme.headlineSmall)
            .animate(key: ValueKey('title$stepIndex'))
            .fadeIn(duration: 260.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        if (subtitle case final String text) ...[
          const SizedBox(height: 6),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ).animate(key: ValueKey('sub$stepIndex')).fadeIn(delay: 80.ms),
        ],
        const SizedBox(height: 24),
        Expanded(
          child: child
              .animate(key: ValueKey('body$stepIndex'))
              .fadeIn(delay: 120.ms, duration: 300.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
        ),
        if (footer case final Widget widget) widget,
      ],
    );
  }
}

/// A row of segments that fill as the user advances.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.stepIndex, required this.stepCount});

  final int stepIndex;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < stepCount; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == stepCount - 1 ? 0 : 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                height: 5,
                decoration: BoxDecoration(
                  color: i <= stepIndex
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
