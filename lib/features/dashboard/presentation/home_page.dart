import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/navigation/app_routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/formatting/app_formats.dart';
import '../../garage/data/garage_providers.dart';
import '../../garage/domain/car_body_style.dart';
import '../../garage/domain/car_paint_color.dart';
import '../../garage/domain/care_score.dart';
import '../../garage/presentation/garage_stage.dart';
import '../../garage/presentation/milestone_strip.dart';
import '../../garage/presentation/rolling_odometer.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../maintenance/domain/maintenance_schedule.dart';
import '../../maintenance/domain/maintenance_status.dart';
import '../../maintenance/presentation/maintenance_record_tile.dart';
import '../../vehicle/data/vehicle_repository.dart';
import '../../vehicle/domain/mileage_freshness.dart';

/// The screen the app opens on: how the car is doing, and what to do next.
///
/// It renders entirely from local data, so it never waits on a network call to
/// appear.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final vehicleAsync = ref.watch(currentVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: switch (vehicleAsync.value) {
          final Vehicle vehicle => _VehicleSelectorTitle(vehicle: vehicle),
          null => const Text('차고'),
        },
        actions: [
          if (config.isDev)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'DEV',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
      body: switch (vehicleAsync) {
        AsyncValue(hasValue: true, value: final Vehicle vehicle) =>
          _VehicleHome(vehicle: vehicle),
        AsyncValue(hasValue: true) => const _NoVehicle(),
        AsyncValue(hasError: true) => const _HomeError(),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: vehicleAsync.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                unawaited(HapticFeedback.selectionClick());
                context.pushNamed(AppRoutes.addMaintenanceName);
              },
              icon: const Icon(Icons.add),
              label: const Text('기록'),
            ),
    );
  }
}

/// The app bar title doubles as the vehicle switcher.
class _VehicleSelectorTitle extends StatelessWidget {
  const _VehicleSelectorTitle({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(AppRoutes.vehicleListName),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(vehicle.displayName, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NoVehicle extends StatelessWidget {
  const _NoVehicle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // An empty garage still shows a car — the app looks like what it
            // is for before anything has been entered.
            const GarageStage(
              style: CarBodyStyle.sedan,
              score: CareScore(
                value: 0,
                overdue: 0,
                dueSoon: 0,
                healthy: 0,
                mileageStale: false,
              ),
            ).animate().fadeIn(duration: 500.ms).scaleXY(begin: 0.94, end: 1),
            const SizedBox(height: 24),
            Text('차고가 비어 있어요', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '차를 등록하면 정비 이력과 다음 교체 시기를 여기에서 확인할 수 있습니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.addVehicleName),
              icon: const Icon(Icons.add),
              label: const Text('차량 등록'),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('차량 정보를 불러오지 못했습니다.', textAlign: TextAlign.center),
      ),
    );
  }
}

class _VehicleHome extends ConsumerWidget {
  const _VehicleHome({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final score = ref.watch(careScoreProvider);
    final tracked = ref.watch(trackedMaintenanceProvider);
    final records = ref.watch(maintenanceRecordsProvider).value ?? const [];
    final milestones = ref.watch(milestonesProvider);
    final statuses =
        ref.watch(maintenanceStatusesProvider).value ??
        const <MaintenanceStatus>[];
    final typeNames = {
      for (final status in statuses) status.typeId: status.typeName,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        GarageStage(
          style: CarBodyStyle.fromId(vehicle.bodyStyle),
          color: CarPaintColor.fromId(vehicle.paintColor),
          score: score,
        ),
        const SizedBox(height: 8),
        _MileageStrip(vehicle: vehicle, score: score),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text('정비 상태', style: theme.textTheme.titleMedium)),
            TextButton(
              onPressed: () =>
                  context.pushNamed(AppRoutes.maintenanceTypesName),
              child: const Text('항목 관리'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (tracked.isEmpty)
          _EmptyStatusHint()
        else
          for (final (index, status) in tracked.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StatusCard(vehicle: vehicle, status: status)
                  .animate()
                  .fadeIn(delay: (60 * index).ms, duration: 300.ms)
                  .slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
        const SizedBox(height: 16),
        Text('기록', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        MilestoneStrip(milestones: milestones),
        const SizedBox(height: 20),
        Text('최근 정비', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '아직 기록이 없습니다. 정비를 마쳤다면 아래 버튼으로 남겨 두세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final record in records.take(3))
            MaintenanceRecordTile(
              record: record,
              typeName: typeNames[record.maintenanceTypeId],
            ),
      ],
    );
  }
}

class _EmptyStatusHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '정비를 기록하면 다음 교체 시기를 여기에서 확인할 수 있습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The odometer line under the stage.
///
/// One row rather than a card: the score already sits on the stage, and the
/// screen's job is to get the user to the maintenance status without scrolling.
class _MileageStrip extends ConsumerWidget {
  const _MileageStrip({required this.vehicle, required this.score});

  final Vehicle vehicle;
  final CareScore score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stale = isMileageStale(
      updatedAt: vehicle.mileageUpdatedAt,
      now: DateTime.now(),
    );

    return Row(
      children: [
        Icon(Icons.speed_outlined, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RollingOdometer(
              kilometres: vehicle.currentMileage,
              style: theme.textTheme.titleLarge,
            ),
            Text(
              stale
                  ? '업데이트하면 더 정확해져요'
                  : '${formatDate(vehicle.mileageUpdatedAt)} 기준',
              style: theme.textTheme.bodySmall?.copyWith(
                color: stale
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        TextButton(
          onPressed: () => editMileage(context, ref, vehicle),
          child: const Text('수정'),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.vehicle, required this.status});

  final Vehicle vehicle;
  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = status.due;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoutes.maintenanceDetailName,
          pathParameters: {
            'vehicleId': '${vehicle.id}',
            'typeId': '${status.typeId}',
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      status.typeName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (due != null) _UrgencyChip(urgency: due.urgency),
                ],
              ),
              const SizedBox(height: 10),
              if (!status.hasRecord)
                Text(
                  '아직 기록이 없어 다음 교체 시기를 계산할 수 없습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                if (due?.dueMileage != null)
                  _DueRow(
                    icon: Icons.speed_outlined,
                    label: formatKilometres(due!.dueMileage!),
                    detail: formatRemainingDistance(due.remainingDistanceKm!),
                  ),
                if (due?.dueDate != null) ...[
                  const SizedBox(height: 6),
                  _DueRow(
                    icon: Icons.event_outlined,
                    label: formatDate(due!.dueDate!),
                    detail: formatRemainingDays(due.remainingDays!),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '마지막 ${formatDate(status.lastServiceDate!)}'
                  ' · ${formatKilometres(status.lastServiceMileage!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DueRow extends StatelessWidget {
  const _DueRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyLarge),
        const Spacer(),
        Text(
          detail,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({required this.urgency});

  final MaintenanceUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (urgency) {
      MaintenanceUrgency.ok => (
        '여유',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      MaintenanceUrgency.dueSoon => (
        '임박',
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      MaintenanceUrgency.overdue => (
        '지남',
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}

/// Asks for a fresh odometer reading.
///
/// Shared with the vehicle list, which offers the same correction.
Future<void> editMileage(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) async {
  final value = await showDialog<int>(
    context: context,
    builder: (context) =>
        _MileageDialog(initialMileage: vehicle.currentMileage),
  );

  if (value != null) {
    unawaited(HapticFeedback.selectionClick());
    await ref.read(vehicleRepositoryProvider).updateMileage(vehicle.id, value);
  }
}

/// Owns its own controller so that it lives exactly as long as the dialog
/// does — disposing it as soon as `showDialog` returns would tear it out from
/// under the closing animation.
class _MileageDialog extends StatefulWidget {
  const _MileageDialog({required this.initialMileage});

  final int initialMileage;

  @override
  State<_MileageDialog> createState() => _MileageDialogState();
}

class _MileageDialogState extends State<_MileageDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initialMileage}',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(int.parse(_controller.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('현재 주행거리'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(suffixText: 'km'),
          onFieldSubmitted: (_) => _submit(),
          validator: (input) {
            final parsed = int.tryParse(input?.trim() ?? '');
            if (parsed == null) {
              return '숫자만 입력해 주세요';
            }
            if (parsed > 2000000) {
              return '주행거리를 다시 확인해 주세요';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
