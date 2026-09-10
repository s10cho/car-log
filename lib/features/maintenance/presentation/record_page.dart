import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/home_page.dart' show MaintenanceRecordTile;
import '../data/maintenance_repository.dart';

/// The full maintenance history for the current vehicle.
class RecordPage extends ConsumerWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(maintenanceRecordsProvider);
    final typeName = ref.watch(engineOilStatusProvider).value?.typeName;

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
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
          itemBuilder: (context, index) =>
              MaintenanceRecordTile(record: records[index], typeName: typeName),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
