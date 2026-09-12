import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maintenance/data/maintenance_repository.dart';
import '../../vehicle/data/vehicle_repository.dart';
import '../../vehicle/domain/mileage_freshness.dart';
import '../domain/care_score.dart';
import '../domain/milestone.dart';

/// How well the vehicle on screen is being looked after.
final careScoreProvider = Provider<CareScore>((ref) {
  final vehicle = ref.watch(currentVehicleProvider).value;
  final statuses = ref.watch(maintenanceStatusesProvider).value ?? const [];

  return calculateCareScore(
    statuses: statuses,
    mileageStale:
        vehicle != null &&
        isMileageStale(
          updatedAt: vehicle.mileageUpdatedAt,
          now: DateTime.now(),
        ),
  );
});

/// Badges for the vehicle on screen.
final milestonesProvider = Provider<List<Milestone>>((ref) {
  final statuses = ref.watch(maintenanceStatusesProvider).value ?? const [];
  final records = ref.watch(maintenanceRecordsProvider).value ?? const [];
  final vehicle = ref.watch(currentVehicleProvider).value;
  final vehicles = ref.watch(vehicleListProvider).value ?? const [];

  final tracked = statuses.where((status) => status.hasRecord).toList();

  return buildMilestones(
    GarageStats(
      recordCount: records.length,
      trackedItemCount: tracked.length,
      catalogueSize: statuses.length,
      mileage: vehicle?.currentMileage ?? 0,
      overdueCount: tracked.where((s) => s.due?.isOverdue ?? false).length,
      vehicleCount: vehicles.length,
      hasReceipt: records.any((record) => record.receiptAssetId != null),
    ),
  );
});
