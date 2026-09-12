import 'package:flutter/material.dart';

import '../domain/milestone.dart';

/// The badge row.
///
/// Locked badges are shown greyed rather than hidden: a badge nobody can see
/// is not a goal. Achieved ones lead, so the row opens on something earned.
class MilestoneStrip extends StatelessWidget {
  const MilestoneStrip({required this.milestones, super.key});

  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordered = [
      ...milestones.where((m) => m.achieved),
      ...milestones.where((m) => !m.achieved),
    ];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ordered.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final milestone = ordered[index];
          return Tooltip(
            message: milestone.description,
            child: Opacity(
              opacity: milestone.achieved ? 1 : 0.38,
              child: Container(
                width: 88,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: milestone.achieved
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: milestone.achieved
                        ? theme.colorScheme.secondary.withValues(alpha: 0.4)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(milestone.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        milestone.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
