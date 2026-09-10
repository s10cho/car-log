import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/formatting/app_formats.dart';
import '../data/vehicle_repository.dart';

/// The vehicle switcher: pick which car the app is showing, or manage the list.
class VehicleListPage extends ConsumerWidget {
  const VehicleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleListProvider).value ?? const [];
    final currentId = ref.watch(currentVehicleProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('차량')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final vehicle in vehicles)
            _VehicleTile(vehicle: vehicle, isCurrent: vehicle.id == currentId),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.addVehicleName),
              icon: const Icon(Icons.add),
              label: const Text('차량 추가'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleTile extends ConsumerWidget {
  const _VehicleTile({required this.vehicle, required this.isCurrent});

  final Vehicle vehicle;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detail = <String>[
      if (vehicle.manufacturer case final String manufacturer) manufacturer,
      if (vehicle.model case final String model) model,
      if (vehicle.modelYear case final int year) '$year년식',
    ].join(' · ');

    return ListTile(
      leading: Icon(
        isCurrent ? Icons.check_circle : Icons.directions_car_outlined,
        color: isCurrent
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
      title: Text(vehicle.displayName),
      subtitle: Text(
        detail.isEmpty
            ? formatKilometres(vehicle.currentMileage)
            : '$detail · ${formatKilometres(vehicle.currentMileage)}',
      ),
      trailing: PopupMenuButton<_VehicleAction>(
        onSelected: (action) => _handle(context, ref, action),
        itemBuilder: (context) => const [
          PopupMenuItem(value: _VehicleAction.edit, child: Text('정보 수정')),
          PopupMenuItem(value: _VehicleAction.delete, child: Text('삭제')),
        ],
      ),
      onTap: isCurrent
          ? () => context.pop()
          : () async {
              await ref.read(vehicleRepositoryProvider).select(vehicle.id);
              if (context.mounted) {
                context.pop();
              }
            },
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _VehicleAction action,
  ) async {
    switch (action) {
      case _VehicleAction.edit:
        await context.pushNamed(
          AppRoutes.editVehicleName,
          pathParameters: {'vehicleId': '${vehicle.id}'},
        );
      case _VehicleAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${vehicle.displayName}을(를) 삭제할까요?'),
            content: const Text('이 차량의 정비 기록과 교체주기 설정도 함께 삭제됩니다. 되돌릴 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
        if (confirmed ?? false) {
          await ref.read(vehicleRepositoryProvider).delete(vehicle.id);
        }
    }
  }
}

enum _VehicleAction { edit, delete }
