import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_formats.dart';
import '../../garage/domain/car_body_style.dart';
import '../../garage/domain/car_paint_color.dart';
import '../../garage/presentation/car_color_picker.dart';
import '../../garage/presentation/car_scene.dart';
import '../../garage/presentation/celebration.dart';
import '../../garage/presentation/wizard_step_scaffold.dart';
import '../data/vehicle_repository.dart';

/// Registers a vehicle one question at a time.
///
/// The old screen showed every field at once, which asks the user to plan
/// their answers before giving any. Registering a car has a natural order —
/// what it is, what you call it, how far it has gone — so the screen follows
/// it and reveals the next question only once the current one is answered.
class VehicleWizardPage extends ConsumerStatefulWidget {
  const VehicleWizardPage({super.key});

  @override
  ConsumerState<VehicleWizardPage> createState() => _VehicleWizardPageState();
}

enum _Step { bodyStyle, paint, name, mileage, details }

class _VehicleWizardPageState extends ConsumerState<VehicleWizardPage> {
  final _name = TextEditingController();
  final _mileage = TextEditingController();
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _modelYear = TextEditingController();
  final _licensePlate = TextEditingController();

  _Step _step = _Step.bodyStyle;
  CarBodyStyle _style = CarBodyStyle.sedan;
  // The shape step shows the car before the colour is asked for, and a white
  // car on a light background is a shape you have to squint at. Red reads at
  // a glance in both themes — and the very next step is where it changes.
  CarPaintColor _color = CarPaintColor.red;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The name and mileage steps gate their own button, so rebuild as typed.
    _name.addListener(_onTyped);
    _mileage.addListener(_onTyped);
  }

  void _onTyped() => setState(() => _error = null);

  @override
  void dispose() {
    _name.dispose();
    _mileage.dispose();
    _manufacturer.dispose();
    _model.dispose();
    _modelYear.dispose();
    _licensePlate.dispose();
    super.dispose();
  }

  int get _stepIndex => _Step.values.indexOf(_step);

  /// Chips summarising what has been answered, so nothing feels lost when the
  /// question disappears.
  List<String> get _answered => [
    if (_stepIndex > 0) _style.label,
    if (_stepIndex > 1) _color.label,
    if (_stepIndex > 2 && _name.text.trim().isNotEmpty) _name.text.trim(),
    if (_stepIndex > 3 && _parsedMileage != null)
      formatKilometres(_parsedMileage!),
  ];

  int? get _parsedMileage => int.tryParse(_mileage.text.trim());

  void _advance(_Step next) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _step = next;
      _error = null;
    });
  }

  void _back() {
    final index = _stepIndex;
    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step = _Step.values[index - 1];
      _error = null;
    });
  }

  Future<void> _save() async {
    final mileage = _parsedMileage;
    if (_name.text.trim().isEmpty || mileage == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(vehicleRepositoryProvider);
      final id = await repository.create(
        displayName: _name.text.trim(),
        currentMileage: mileage,
        bodyStyle: _style.id,
        paintColor: _color.id,
        manufacturer: _nullIfBlank(_manufacturer.text),
        model: _nullIfBlank(_model.text),
        modelYear: int.tryParse(_modelYear.text.trim()),
        licensePlate: _nullIfBlank(_licensePlate.text),
      );
      await repository.select(id);

      if (mounted) {
        celebrate(context, message: '${_name.text.trim()} 를 차고에 넣었어요');
        Navigator.of(context).pop();
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '차량을 저장하지 못했습니다. 다시 시도해 주세요.';
        });
      }
    }
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _back),
        title: const Text('차량 등록'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: switch (_step) {
            _Step.bodyStyle => _bodyStyleStep(),
            _Step.paint => _paintStep(),
            _Step.name => _nameStep(),
            _Step.mileage => _mileageStep(),
            _Step.details => _detailsStep(),
          },
        ),
      ),
    );
  }

  Widget _bodyStyleStep() {
    return WizardStepScaffold(
      title: '어떤 차인가요?',
      subtitle: '가장 비슷한 모양을 고르세요. 나중에 바꿀 수 있습니다.',
      stepIndex: 0,
      stepCount: _Step.values.length,
      // The picker belongs with the action rather than inside the body: on a
      // short screen a row at the bottom of a flexible body ends up underneath
      // the button, where it cannot be tapped at all.
      footer: Column(
        children: [
          Text(
            _style.label,
            style: Theme.of(context).textTheme.titleLarge,
          ).animate(key: ValueKey(_style)).fadeIn(duration: 200.ms),
          const SizedBox(height: 10),
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
                  onSelected: (_) {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _style = style);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _NextButton(label: '다음', onPressed: () => _advance(_Step.paint)),
        ],
      ),
      child: CarScene(
        style: _style,
        color: _color,
        pose: CarPose.showcase,
        height: double.infinity,
      ),
    );
  }

  Widget _paintStep() {
    return WizardStepScaffold(
      title: '무슨 색인가요?',
      subtitle: '차고에 세워 둘 색입니다. 나중에 바꿀 수 있습니다.',
      stepIndex: 1,
      stepCount: _Step.values.length,
      answered: _answered,
      // Same reason as the shape step: the picker sits with the button so a
      // short screen cannot slide it underneath.
      footer: Column(
        children: [
          Text(
            _color.label,
            style: Theme.of(context).textTheme.titleLarge,
          ).animate(key: ValueKey(_color)).fadeIn(duration: 200.ms),
          const SizedBox(height: 10),
          CarColorPicker(
            selected: _color,
            onSelected: (color) => setState(() => _color = color),
          ),
          const SizedBox(height: 16),
          _NextButton(label: '다음', onPressed: () => _advance(_Step.name)),
        ],
      ),
      child: CarScene(
        style: _style,
        color: _color,
        pose: CarPose.parked,
        height: double.infinity,
      ),
    );
  }

  Widget _nameStep() {
    final ready = _name.text.trim().isNotEmpty;
    return WizardStepScaffold(
      title: '이 차를 뭐라고 부를까요?',
      subtitle: '차고에서 이 이름으로 보입니다.',
      stepIndex: 2,
      stepCount: _Step.values.length,
      answered: _answered,
      footer: _NextButton(
        label: '다음',
        onPressed: ready ? () => _advance(_Step.mileage) : null,
      ),
      child: TextField(
        controller: _name,
        autofocus: true,
        textInputAction: TextInputAction.next,
        style: Theme.of(context).textTheme.headlineSmall,
        decoration: const InputDecoration(
          hintText: '내 아반떼',
          border: UnderlineInputBorder(),
        ),
        onSubmitted: (_) {
          if (ready) {
            _advance(_Step.mileage);
          }
        },
      ),
    );
  }

  Widget _mileageStep() {
    final ready = (_parsedMileage ?? -1) >= 0 && _parsedMileage! <= 2000000;
    return WizardStepScaffold(
      title: '지금 주행거리는요?',
      subtitle: '계기판에 보이는 숫자를 그대로 적어 주세요. 다음 교체 시기를 계산하는 기준입니다.',
      stepIndex: 3,
      stepCount: _Step.values.length,
      answered: _answered,
      footer: _NextButton(
        label: '다음',
        onPressed: ready ? () => _advance(_Step.details) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _mileage,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              hintText: '32000',
              suffixText: 'km',
              border: UnderlineInputBorder(),
            ),
            onSubmitted: (_) {
              if (ready) {
                _advance(_Step.details);
              }
            },
          ),
          if (_parsedMileage case final int value) ...[
            const SizedBox(height: 12),
            Text(
              formatKilometres(value),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsStep() {
    return WizardStepScaffold(
      title: '거의 끝났어요',
      subtitle: '아래는 모두 선택 사항입니다. 비워 두고 바로 시작해도 됩니다.',
      stepIndex: 4,
      stepCount: _Step.values.length,
      answered: _answered,
      footer: Column(
        children: [
          if (_error case final String message)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _NextButton(
            label: _saving ? '저장 중…' : '차고에 넣기',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      child: ListView(
        children: [
          _OptionalField(controller: _manufacturer, label: '제조사', hint: '현대'),
          _OptionalField(controller: _model, label: '모델', hint: '아반떼 CN7'),
          _OptionalField(
            controller: _modelYear,
            label: '연식',
            hint: '2021',
            numeric: true,
          ),
          _OptionalField(
            controller: _licensePlate,
            label: '차량번호',
            hint: '12가3456',
          ),
        ],
      ),
    );
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.controller,
    required this.label,
    required this.hint,
    this.numeric = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: numeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
      child: Text(label),
    );
  }
}
