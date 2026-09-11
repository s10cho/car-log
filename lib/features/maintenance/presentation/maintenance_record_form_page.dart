import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/formatting/app_formats.dart';
import '../../receipt/data/receipt_picker.dart';
import '../../receipt/domain/picked_receipt.dart';
import '../../receipt/presentation/receipt_picker_sheet.dart';
import '../../vehicle/data/vehicle_repository.dart';
import '../data/maintenance_repository.dart';

/// Records one completed service.
///
/// Date and mileage are required because the next due point is projected from
/// them — everything else is optional so that the common case stays a
/// ten-second job.
class MaintenanceRecordFormPage extends ConsumerStatefulWidget {
  const MaintenanceRecordFormPage({this.recordId, super.key});

  /// Null when adding, set when editing.
  final int? recordId;

  bool get isEditing => recordId != null;

  @override
  ConsumerState<MaintenanceRecordFormPage> createState() =>
      _MaintenanceRecordFormPageState();
}

class _MaintenanceRecordFormPageState
    extends ConsumerState<MaintenanceRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _mileage = TextEditingController();
  final _cost = TextEditingController();
  final _shopName = TextEditingController();
  final _memo = TextEditingController();

  DateTime _date = DateTime.now();

  /// Null until the user picks one; the build falls back to 엔진오일.
  int? _typeId;
  PickedReceipt? _receipt;

  /// The receipt already stored against the record being edited.
  ReceiptAsset? _existingReceipt;
  bool _removeReceipt = false;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    final repository = ref.read(maintenanceRepositoryProvider);
    final record = await repository.findRecord(widget.recordId!);
    final receipt = await repository.receiptFor(widget.recordId!);
    if (!mounted) {
      return;
    }

    if (record != null) {
      _typeId = record.maintenanceTypeId;
      _date = record.maintenanceDate;
      _mileage.text = '${record.mileage}';
      _cost.text = record.cost?.toString() ?? '';
      _shopName.text = record.shopName ?? '';
      _memo.text = record.memo ?? '';
      _existingReceipt = receipt;
    }
    setState(() => _loading = false);
  }

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
      final repository = ref.read(maintenanceRepositoryProvider);
      if (widget.isEditing) {
        await repository.updateRecord(
          recordId: widget.recordId!,
          maintenanceTypeId: typeId,
          maintenanceDate: _date,
          mileage: int.parse(_mileage.text.trim()),
          cost: int.tryParse(_cost.text.trim()),
          shopName: _nullIfBlank(_shopName.text),
          memo: _nullIfBlank(_memo.text),
          receipt: _receipt,
          removeReceipt: _removeReceipt,
        );
      } else {
        await repository.addRecord(
          vehicleId: vehicle.id,
          maintenanceTypeId: typeId,
          maintenanceDate: _date,
          mileage: int.parse(_mileage.text.trim()),
          cost: int.tryParse(_cost.text.trim()),
          shopName: _nullIfBlank(_shopName.text),
          memo: _nullIfBlank(_memo.text),
          receipt: _receipt,
        );
      }
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 기록을 삭제할까요?'),
        content: const Text('첨부한 영수증도 함께 삭제됩니다. 되돌릴 수 없습니다.'),
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
    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(maintenanceRepositoryProvider)
          .deleteRecord(widget.recordId!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('기록을 삭제하지 못했습니다.')));
      }
    }
  }

  Future<void> _pickReceipt() async {
    final source = await showReceiptSourceSheet(context);
    if (source == null || !mounted) {
      return;
    }

    try {
      final picked = await ref.read(receiptPickerProvider).pick(source);
      if (picked != null && mounted) {
        setState(() {
          _receipt = picked;
          _removeReceipt = false;
        });
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('영수증을 불러오지 못했습니다.')));
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

    if (_loading || vehicle == null || types == null || types.isEmpty) {
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
      appBar: AppBar(
        title: Text(widget.isEditing ? '기록 수정' : '정비 기록'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '기록 삭제',
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
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
            const SizedBox(height: 16),
            _ReceiptField(
              receipt: _receipt,
              existing: _removeReceipt ? null : _existingReceipt,
              onPick: _pickReceipt,
              onClear: () => setState(() {
                _receipt = null;
                // Clearing a stored receipt has to be remembered: the form
                // only tells the repository to remove it on save.
                _removeReceipt = _existingReceipt != null;
              }),
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

/// The receipt slot on the record form: empty, or showing what will be saved.
class _ReceiptField extends StatelessWidget {
  const _ReceiptField({
    required this.receipt,
    required this.existing,
    required this.onPick,
    required this.onClear,
  });

  /// A file the user just chose, which replaces [existing] on save.
  final PickedReceipt? receipt;

  /// What is already stored against the record being edited.
  final ReceiptAsset? existing;

  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attached = receipt;

    if (attached == null && existing != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(
            existing!.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('첨부됨', style: theme.textTheme.bodySmall),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onPick, child: const Text('교체')),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: '첨부 삭제',
                onPressed: onClear,
              ),
            ],
          ),
        ),
      );
    }

    if (attached == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('영수증 첨부'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      );
    }

    return Card(
      child: ListTile(
        leading: attached.isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  attached.file,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              )
            : const Icon(Icons.description_outlined),
        title: Text(
          attached.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('저장 시 함께 보관됩니다', style: theme.textTheme.bodySmall),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: '첨부 취소',
          onPressed: onClear,
        ),
      ),
    );
  }
}
