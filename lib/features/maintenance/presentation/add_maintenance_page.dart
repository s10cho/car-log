import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/formatting/app_formats.dart';
import '../../vehicle/data/vehicle_repository.dart';
import '../data/maintenance_repository.dart';

/// Records one completed service.
///
/// Slice 1 covers 엔진오일 only; the item picker arrives with the rest of the
/// catalogue in Slice 3. Date and mileage are required because the next due
/// point is projected from them — everything else is optional so that the
/// common case stays a ten-second job.
class AddMaintenancePage extends ConsumerStatefulWidget {
  const AddMaintenancePage({super.key});

  @override
  ConsumerState<AddMaintenancePage> createState() => _AddMaintenancePageState();
}

class _AddMaintenancePageState extends ConsumerState<AddMaintenancePage> {
  final _formKey = GlobalKey<FormState>();
  final _mileage = TextEditingController();
  final _cost = TextEditingController();
  final _shopName = TextEditingController();
  final _memo = TextEditingController();

  DateTime _date = DateTime.now();

  /// Null until the user picks one; the build falls back to 엔진오일.
  int? _typeId;
  bool _saving = false;

  @override
  void dispose() {
    _mileage.dispose();
    _cost.dispose();
    _shopName.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: '정비 날짜',
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save(Vehicle vehicle, int typeId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .addRecord(
            vehicleId: vehicle.id,
            maintenanceTypeId: typeId,
            maintenanceDate: _date,
            mileage: int.parse(_mileage.text.trim()),
            cost: int.tryParse(_cost.text.trim()),
            shopName: _nullIfBlank(_shopName.text),
            memo: _nullIfBlank(_memo.text),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록을 저장하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(currentVehicleProvider).value;
    final types = ref.watch(maintenanceTypesProvider).value;

    if (vehicle == null || types == null || types.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 기본 선택은 엔진오일 — 가장 자주 기록하는 항목이다.
    final selectedId =
        _typeId ??
        types
            .firstWhere(
              (type) => type.code == engineOilTypeCode,
              orElse: () => types.first,
            )
            .id;

    return Scaffold(
      appBar: AppBar(title: const Text('정비 기록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                labelText: '정비 항목',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final type in types)
                  DropdownMenuItem(value: type.id, child: Text(type.name)),
              ],
              onChanged: (value) => setState(() => _typeId = value),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('정비 날짜'),
              subtitle: Text(formatDate(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('변경'),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mileage,
              autofocus: true,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: '정비 시 주행거리 (km)',
                hintText: '현재 ${formatKilometres(vehicle.currentMileage)}',
                border: const OutlineInputBorder(),
              ),
              validator: _validateMileage,
            ),
            const SizedBox(height: 24),
            Text(
              '아래는 선택 사항입니다',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '비용 (원)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shopName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '정비소',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _memo,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '메모',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
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
          onPressed: _saving ? null : () => _save(vehicle, selectedId),
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

String? _validateMileage(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '주행거리를 입력해 주세요';
  }
  final parsed = int.tryParse(trimmed);
  if (parsed == null) {
    return '숫자만 입력해 주세요';
  }
  if (parsed > 2000000) {
    return '주행거리를 다시 확인해 주세요';
  }
  return null;
}
