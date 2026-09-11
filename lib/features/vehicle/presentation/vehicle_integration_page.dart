import 'package:flutter/material.dart';

/// Says where automatic mileage stands, honestly.
///
/// The screen exists because the alternative is worse: a missing menu leaves
/// the user wondering whether they missed a setting, and a "곧 지원" label would
/// be a promise the app cannot keep. See `docs/connected-car.md`.
class VehicleIntegrationPage extends StatelessWidget {
  const VehicleIntegrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('차량 연동')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                Icons.link_off,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('연동되지 않음'),
              subtitle: const Text('주행거리를 직접 입력합니다'),
            ),
          ),
          const SizedBox(height: 24),
          Text('왜 아직 연동이 없나요', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '현대·기아의 공식 차량 데이터 API 는 앱에 숨길 수 없는 비밀 키를 요구합니다. '
            '앱 파일은 누구나 뜯어볼 수 있어서, 그 키를 넣으면 이 앱의 이름으로 다른 사람의 '
            '차량 데이터에 접근할 수 있는 통로가 됩니다.\n\n'
            '안전하게 연동하려면 키를 보관할 서버가 필요한데, 그러면 여러분의 차량 정보가 '
            '저희 서버를 지나가게 됩니다. 그 결정을 먼저 하지 않고 만들지 않기로 했습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text('그동안은', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '홈 화면에서 주행거리를 직접 수정할 수 있고, 정비를 기록할 때 입력한 주행거리가 '
            '자동으로 반영됩니다. 마지막 업데이트가 오래되면 홈에서 알려 드립니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
