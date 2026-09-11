import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/formatting/app_formats.dart';
import '../../receipt/presentation/receipt_view.dart';
import '../data/maintenance_repository.dart';

/// One maintenance record in a list. Tapping it opens the record for editing.
class MaintenanceRecordTile extends ConsumerWidget {
  const MaintenanceRecordTile({
    required this.record,
    this.typeName,
    this.showReceiptAction = false,
    super.key,
  });

  final MaintenanceRecord record;
  final String? typeName;

  /// Whether to offer the attached receipt alongside the row, as the
  /// maintenance detail does.
  final bool showReceiptAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitle = <String>[
      formatKilometres(record.mileage),
      if (record.cost case final int cost) formatWon(cost),
      if (record.shopName case final String shop) shop,
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.build_outlined),
      title: Text(typeName ?? '정비'),
      subtitle: Text(subtitle),
      onTap: () => context.pushNamed(
        AppRoutes.editMaintenanceName,
        pathParameters: {'recordId': '${record.id}'},
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDate(record.maintenanceDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (showReceiptAction && record.receiptAssetId != null)
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
