import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository.dart';
import '../domain/maintenance_schedule.dart';
import '../domain/maintenance_status.dart';

/// Lets the user override the recommended interval for this vehicle.
///
/// Both dimensions are optional, but clearing both would leave nothing to
/// calculate from, so at least one is required.
class MaintenanceIntervalPage extends ConsumerStatefulWidget {
  const MaintenanceIntervalPage({
    required this.vehicleId,
    required this.typeId,
    super.key,
  });

  final int vehicleId;
  final int typeId;

  @override
  ConsumerState<MaintenanceIntervalPage> createState() =>
      _MaintenanceIntervalPageState();
}

class _MaintenanceIntervalPageState
    extends ConsumerState<MaintenanceIntervalPage> {
  final _formKey = GlobalKey<FormState>();
  final _distance = TextEditingController();
  final _months = TextEditingController();

  bool _initialised = false;
  bool _saving = false;

  @override
  void dispose() {
    _distance.dispose();
    _months.dispose();
    super.dispose();
  }

  void _fillOnce(MaintenanceStatus status) {
    if (_initialised) {
      return;
    }
    _initialised = true;
    _distance.text = status.interval.distanceKm?.toString() ?? '';
    _months.text = status.interval.months?.toString() ?? '';
  }

  Future<void> _save(MaintenanceStatus status) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .setInterval(
            vehicleId: widget.vehicleId,
            maintenanceTypeId: status.typeId,
            interval: MaintenanceInterval(
              distanceKm: int.tryParse(_distance.text.trim()),
              months: int.tryParse(_months.text.trim()),
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('교체주기를 저장하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  String? _validateAtLeastOne(String? _) {
    if (_distance.text.trim().isEmpty && _months.text.trim().isEmpty) {
      return '주행거리와 기간 중 하나는 입력해 주세요';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final status = ref
        .watch(maintenanceStatusesProvider)
        .value
        ?.where((status) => status.typeId == widget.typeId)
        .firstOrNull;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _fillOnce(status);

    return Scaffold(
      appBar: AppBar(title: Text('${status.typeName} 교체주기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              '둘 다 입력하면 먼저 도래하는 쪽을 기준으로 알려 드립니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _distance,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '주행거리 기준 (km)',
                border: OutlineInputBorder(),
              ),
              validator: _validateAtLeastOne,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _months,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '기간 기준 (개월)',
                border: OutlineInputBorder(),
              ),
              validator: _validateAtLeastOne,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          8 + MediaQuery.of(context).padding.bottom,
        ),
        child: FilledButton(
          onPressed: _saving ? null : () => _save(status),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ),
    );
  }
}
