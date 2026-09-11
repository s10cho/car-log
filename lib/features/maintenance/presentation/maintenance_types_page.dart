import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/formatting/app_formats.dart';
import '../data/maintenance_repository.dart';
import '../domain/maintenance_schedule.dart';

/// Manages the catalogue of maintenance items and their recommended intervals.
///
/// These are the app-wide defaults. A single vehicle can still override any of
/// them from its status card on the home screen.
class MaintenanceTypesPage extends ConsumerWidget {
  const MaintenanceTypesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final types = ref.watch(maintenanceTypesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('정비 항목'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '항목 추가',
            onPressed: () => _edit(context, ref, null),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              '기본 주기는 일반적인 권장값입니다. 차량과 운행 조건에 따라 다르니 필요하면 고쳐서 쓰세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final type in types) _TypeTile(type: type),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TypeTile extends ConsumerWidget {
  const _TypeTile({required this.type});

  final MaintenanceType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(type.name),
      subtitle: Text(
        _intervalLabel(
          MaintenanceInterval(
            distanceKm: type.defaultDistanceInterval,
            months: type.defaultTimeIntervalMonths,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!type.isBuiltIn)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
              onPressed: () => _delete(context, ref, type),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '수정',
            onPressed: () => _edit(context, ref, type),
          ),
        ],
      ),
    );
  }
}

String _intervalLabel(MaintenanceInterval interval) {
  final parts = <String>[
    if (interval.distanceKm case final int km) formatKilometres(km),
    if (interval.months case final int months) '$months개월',
  ];
  return parts.isEmpty ? '주기 없음' : parts.join(' 또는 ');
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  MaintenanceType type,
) async {
  final repository = ref.read(maintenanceRepositoryProvider);
  final inUse = await repository.recordCountForType(type.id);

  if (!context.mounted) {
    return;
  }

  // Records point at the type, so removing one that is in use would take
  // history with it. Say so instead of silently failing.
  if (inUse > 0) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type.name}을(를) 삭제할 수 없습니다'),
        content: Text('이 항목으로 남긴 정비 기록이 $inUse건 있습니다. 기록을 먼저 지워 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${type.name}을(를) 삭제할까요?'),
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
    await repository.deleteType(type.id);
  }
}

Future<void> _edit(
  BuildContext context,
  WidgetRef ref,
  MaintenanceType? type,
) async {
  final result = await showDialog<_TypeDraft>(
    context: context,
    builder: (context) => _TypeDialog(type: type),
  );
  if (result == null) {
    return;
  }

  final repository = ref.read(maintenanceRepositoryProvider);
  if (type == null) {
    await repository.createCustomType(
      name: result.name,
      distanceInterval: result.distanceKm,
      timeIntervalMonths: result.months,
    );
  } else {
    await repository.updateType(
      id: type.id,
      name: result.name,
      distanceInterval: result.distanceKm,
      timeIntervalMonths: result.months,
    );
  }
}

class _TypeDraft {
  const _TypeDraft({required this.name, this.distanceKm, this.months});

  final String name;
  final int? distanceKm;
  final int? months;
}

class _TypeDialog extends StatefulWidget {
  const _TypeDialog({this.type});

  final MaintenanceType? type;

  @override
  State<_TypeDialog> createState() => _TypeDialogState();
}

class _TypeDialogState extends State<_TypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.type?.name ?? '',
  );
  late final TextEditingController _distance = TextEditingController(
    text: widget.type?.defaultDistanceInterval?.toString() ?? '',
  );
  late final TextEditingController _months = TextEditingController(
    text: widget.type?.defaultTimeIntervalMonths?.toString() ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _distance.dispose();
    _months.dispose();
    super.dispose();
  }

  String? _requireOneInterval(String? _) {
    if (_distance.text.trim().isEmpty && _months.text.trim().isEmpty) {
      return '주행거리와 기간 중 하나는 입력해 주세요';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _TypeDraft(
        name: _name.text.trim(),
        distanceKm: int.tryParse(_distance.text.trim()),
        months: int.tryParse(_months.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.type == null ? '항목 추가' : '항목 수정'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '항목 이름',
                hintText: '예) 하부 코팅',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '항목 이름을 입력해 주세요'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distance,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '주행거리 기준',
                suffixText: 'km',
              ),
              validator: _requireOneInterval,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _months,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '기간 기준',
                suffixText: '개월',
              ),
              validator: _requireOneInterval,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
