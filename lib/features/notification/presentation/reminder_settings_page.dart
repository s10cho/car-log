import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_scheduler_port.dart';
import '../data/reminder_settings_repository.dart';
import '../domain/reminder_plan.dart';

/// Turns reminders on or off and decides when they arrive.
class ReminderSettingsPage extends ConsumerWidget {
  const ReminderSettingsPage({super.key});

  static const List<int> _leadChoices = [1, 3, 7, 14, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(reminderSettingsProvider).value;

    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('정비 알림'),
            subtitle: const Text('교체 시기가 다가오면 알려 드립니다'),
            value: settings.enabled,
            onChanged: (enabled) =>
                _setEnabled(context, ref, settings, enabled),
          ),
          const Divider(height: 1),
          ListTile(
            enabled: settings.enabled,
            title: const Text('며칠 전에 알릴까요'),
            subtitle: Text('${settings.leadDays}일 전'),
            trailing: DropdownButton<int>(
              value: settings.leadDays,
              onChanged: settings.enabled
                  ? (days) => _save(ref, settings.copyWith(leadDays: days))
                  : null,
              items: [
                for (final days in _leadChoices)
                  DropdownMenuItem(value: days, child: Text('$days일 전')),
              ],
            ),
          ),
          ListTile(
            enabled: settings.enabled,
            title: const Text('알림 시각'),
            subtitle: Text('${settings.hourOfDay}시'),
            trailing: DropdownButton<int>(
              value: settings.hourOfDay,
              onChanged: settings.enabled
                  ? (hour) => _save(ref, settings.copyWith(hourOfDay: hour))
                  : null,
              items: [
                for (var hour = 7; hour <= 22; hour++)
                  DropdownMenuItem(value: hour, child: Text('$hour시')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '주행거리 기준 항목은 앱을 열었을 때 홈에서 상태로 확인합니다. '
              '앱이 닫혀 있는 동안에는 주행거리를 알 수 없어 날짜 기준 항목만 알림이 갑니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings settings,
    bool enabled,
  ) async {
    if (!enabled) {
      await _save(ref, settings.copyWith(enabled: false));
      return;
    }

    // Ask for permission only now, when the user has said they want reminders.
    final granted = await ref
        .read(notificationSchedulerProvider)
        .requestPermission();

    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기기 설정에서 알림을 허용해야 알려 드릴 수 있습니다.')),
        );
      }
      return;
    }

    await _save(ref, settings.copyWith(enabled: true));
  }

  Future<void> _save(WidgetRef ref, ReminderSettings settings) =>
      ref.read(reminderSettingsRepositoryProvider).write(settings);
}
