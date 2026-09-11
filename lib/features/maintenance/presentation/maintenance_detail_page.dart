import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/formatting/app_formats.dart';
import '../../../core/database/app_database.dart';
import '../../receipt/presentation/receipt_view.dart';
import '../data/maintenance_repository.dart';
import '../domain/maintenance_schedule.dart';
import '../domain/maintenance_status.dart';

/// One maintenance item on one vehicle: when it was last done, when it is due,
/// and everything recorded for it.
///
/// This is where a reminder lands when the user taps it.
class MaintenanceDetailPage extends ConsumerWidget {
  const MaintenanceDetailPage({
    required this.vehicleId,
    required this.typeId,
    super.key,
  });

  final int vehicleId;
  final int typeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rows = ref.watch(allMaintenanceStatusesProvider).value ?? const [];
    final row = rows
        .where((r) => r.vehicleId == vehicleId && r.status.typeId == typeId)
        .firstOrNull;

    if (row == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final status = row.status;
    final records = (ref.watch(maintenanceRecordsProvider).value ?? const [])
        .where((record) => record.maintenanceTypeId == typeId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(status.typeName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(row.vehicleName, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          _DueSummary(status: status),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('교체주기'),
            subtitle: Text(_intervalLabel(status.interval)),
            trailing: TextButton(
              onPressed: () => context.pushNamed(
                AppRoutes.maintenanceIntervalName,
                pathParameters: {
                  'vehicleId': '$vehicleId',
                  'typeId': '$typeId',
                },
              ),
              child: const Text('수정'),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('이 항목 알림'),
            subtitle: const Text('교체 시기가 가까워지면 알려 드립니다'),
            value: row.notificationEnabled,
            onChanged: (enabled) => ref
                .read(maintenanceRepositoryProvider)
                .setNotificationEnabled(
                  vehicleId: vehicleId,
                  maintenanceTypeId: typeId,
                  enabled: enabled,
                ),
          ),
          const Divider(height: 32),
          Text('이 항목의 기록', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (records.isEmpty)
            Text(
              '아직 기록이 없습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final record in records)
              _RecordWithReceipt(record: record, typeName: status.typeName),
        ],
      ),
    );
  }
}

class _DueSummary extends StatelessWidget {
  const _DueSummary({required this.status});

  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = status.due;

    if (!status.hasRecord) {
      return Text(
        '아직 기록이 없어 다음 교체 시기를 계산할 수 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '마지막 교체 ${formatDate(status.lastServiceDate!)}'
          ' · ${formatKilometres(status.lastServiceMileage!)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (due?.dueMileage != null)
          Text(
            '다음 교체 ${formatKilometres(due!.dueMileage!)}'
            ' · ${formatRemainingDistance(due.remainingDistanceKm!)}',
            style: theme.textTheme.bodyLarge,
          ),
        if (due?.dueDate != null) ...[
          const SizedBox(height: 4),
          Text(
            '다음 교체 ${formatDate(due!.dueDate!)}'
            ' · ${formatRemainingDays(due.remainingDays!)}',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}

String _intervalLabel(MaintenanceInterval interval) {
  final parts = <String>[
    if (interval.distanceKm case final int km) formatKilometres(km),
    if (interval.months case final int months) '$months개월',
  ];
  return parts.isEmpty ? '설정 없음' : parts.join(' 또는 ');
}

/// A record row that also offers its receipt, when one is attached.
class _RecordWithReceipt extends ConsumerWidget {
  const _RecordWithReceipt({required this.record, required this.typeName});

  final MaintenanceRecord record;
  final String typeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = <String>[
      formatKilometres(record.mileage),
      if (record.cost case final int cost) formatWon(cost),
      if (record.shopName case final String shop) shop,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.build_outlined),
      title: Text(typeName),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDate(record.maintenanceDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (record.receiptAssetId != null)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: '영수증 보기',
              onPressed: () => _openReceipt(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _openReceipt(BuildContext context, WidgetRef ref) async {
    final asset = await ref
        .read(maintenanceRepositoryProvider)
        .receiptFor(record.id);
    if (asset == null || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReceiptViewPage(asset: asset),
      ),
    );
  }
}
