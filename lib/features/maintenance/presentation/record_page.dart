import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/home_page.dart' show MaintenanceRecordTile;
import '../../vehicle/data/vehicle_repository.dart';
import '../data/maintenance_repository.dart';
import '../domain/maintenance_status.dart';

/// The full maintenance history for the current vehicle.
class RecordPage extends ConsumerWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(maintenanceRecordsProvider);
    final typeNames = {
      for (final status
          in ref.watch(maintenanceStatusesProvider).value ??
              const <MaintenanceStatus>[])
        status.typeId: status.typeName,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        // Records are per vehicle, so say which one is being listed.
        bottom: switch (ref.watch(currentVehicleProvider).value?.displayName) {
          final String name => PreferredSize(
            preferredSize: const Size.fromHeight(28),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(name, style: theme.textTheme.bodyMedium),
              ),
            ),
          ),
          null => null,
        },
      ),
      body: switch (recordsAsync) {
        AsyncValue(hasError: true) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('기록을 불러오지 못했습니다.', style: theme.textTheme.bodyLarge),
          ),
        ),
        AsyncValue(hasValue: true, value: final records)
            when records!.isEmpty =>
          Center(
            child: Text(
              '정비 기록이 없습니다',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        AsyncValue(hasValue: true, value: final records) => ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: records!.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => MaintenanceRecordTile(
            record: records[index],
            typeName: typeNames[records[index].maintenanceTypeId],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
