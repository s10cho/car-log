import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../garage/domain/car_body_style.dart';
import '../../garage/presentation/car_scene.dart';
import '../data/vehicle_repository.dart';

/// Registers a new vehicle, or edits an existing one when [vehicleId] is given.
///
/// Manual entry only: looking a car up by plate or VIN needs an API whose
/// commercial availability is still unverified (docs/decisions.md).
class VehicleFormPage extends ConsumerStatefulWidget {
  const VehicleFormPage({this.vehicleId, super.key});

  /// Null when registering, set when editing.
  final int? vehicleId;

  bool get isEditing => vehicleId != null;

  @override
  ConsumerState<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends ConsumerState<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _modelYear = TextEditingController();
  final _licensePlate = TextEditingController();
  final _mileage = TextEditingController();

  bool _loading = false;
  bool _saving = false;

  /// Carried through the form so saving cannot quietly clear it.
  CarBodyStyle _style = CarBodyStyle.fallback;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final vehicle = await ref
        .read(vehicleRepositoryProvider)
        .findById(widget.vehicleId!);
    if (!mounted) {
      return;
    }
    if (vehicle != null) {
      _fill(vehicle);
    }
    setState(() => _loading = false);
  }

  void _fill(Vehicle vehicle) {
    _style = CarBodyStyle.fromId(vehicle.bodyStyle);
    _displayName.text = vehicle.displayName;
    _manufacturer.text = vehicle.manufacturer ?? '';
    _model.text = vehicle.model ?? '';
    _modelYear.text = vehicle.modelYear?.toString() ?? '';
    _licensePlate.text = vehicle.licensePlate ?? '';
  }

  @override
  void dispose() {
    _displayName.dispose();
    _manufacturer.dispose();
    _model.dispose();
    _modelYear.dispose();
    _licensePlate.dispose();
    _mileage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final repository = ref.read(vehicleRepositoryProvider);
    try {
      if (widget.isEditing) {
        await repository.update(
          id: widget.vehicleId!,
          displayName: _displayName.text.trim(),
          bodyStyle: _style.id,
          manufacturer: _nullIfBlank(_manufacturer.text),
          model: _nullIfBlank(_model.text),
          modelYear: int.tryParse(_modelYear.text.trim()),
          licensePlate: _nullIfBlank(_licensePlate.text),
        );
      } else {
        final id = await repository.create(
          displayName: _displayName.text.trim(),
          currentMileage: int.parse(_mileage.text.trim()),
          bodyStyle: _style.id,
          manufacturer: _nullIfBlank(_manufacturer.text),
          model: _nullIfBlank(_model.text),
          modelYear: int.tryParse(_modelYear.text.trim()),
          licensePlate: _nullIfBlank(_licensePlate.text),
        );
        // A newly added vehicle is the one the user wants to look at.
        await repository.select(id);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차량을 저장하지 못했습니다. 다시 시도해 주세요.')),
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '차량 정보 수정' : '차량 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (widget.isEditing) ...[
              SizedBox(
                height: 150,
                child: CarScene(style: _style, height: 150),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CarBodyStyle.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final style = CarBodyStyle.values[index];
                    return ChoiceChip(
                      selected: style == _style,
                      label: Text(style.label),
                      avatar: Icon(style.icon, size: 18),
                      onSelected: (_) => setState(() => _style = style),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _displayName,
              autofocus: !widget.isEditing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '차량 이름',
                hintText: '예) 내 아반떼',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '차량 이름을 입력해 주세요'
                  : null,
            ),
            const SizedBox(height: 16),
            if (!widget.isEditing)
              TextFormField(
                controller: _mileage,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '현재 주행거리 (km)',
                  hintText: '예) 32000',
                  border: OutlineInputBorder(),
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
              controller: _manufacturer,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '제조사',
                hintText: '예) 현대',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _model,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '모델',
                hintText: '예) 아반떼 CN7',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelYear,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '연식',
                hintText: '예) 2021',
                border: OutlineInputBorder(),
              ),
              validator: _validateModelYear,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licensePlate,
              decoration: const InputDecoration(
                labelText: '차량번호',
                hintText: '예) 12가3456',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 16),
              Text(
                '주행거리는 홈 화면에서 수정합니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
          onPressed: _saving ? null : _save,
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
    return '현재 주행거리를 입력해 주세요';
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

String? _validateModelYear(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  final parsed = int.tryParse(trimmed);
  if (parsed == null || parsed < 1900 || parsed > 2100) {
    return '연식을 다시 확인해 주세요';
  }
  return null;
}
