import 'package:flutter/material.dart';

/// What the app does with the user's data, in plain language.
///
/// Short because there is little to say: nothing leaves the device unless the
/// user sends it somewhere, and this screen has to stay true as the app grows.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget section(String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 처리방침')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section(
            '데이터는 기기에 있습니다',
            '차량 정보, 정비 기록, 영수증 사진은 모두 이 기기 안에만 저장됩니다. '
                '계정도, 로그인도, 저희 서버도 없습니다. 앱을 지우면 데이터도 함께 사라지니 '
                '백업을 만들어 두세요.',
          ),
          section(
            '앱이 스스로 보내는 것은 없습니다',
            '데이터가 기기 밖으로 나가는 경우는 두 가지뿐이고, 둘 다 사용자가 직접 시작합니다.\n\n'
                '· 영수증을 AI 로 분석할 때: 그 영수증 사진 한 장이 사용자가 선택한 AI 서비스로 '
                '전송됩니다. 처음 분석하기 전에 동의를 묻고, 어느 서비스로 가는지 알려 드립니다. '
                'AI 를 연결하지 않으면 아무것도 전송되지 않습니다.\n\n'
                '· 백업을 내보낼 때: 사용자가 고른 곳(파일, iCloud, Google Drive 등)으로 '
                '백업 파일이 저장됩니다.',
          ),
          section(
            'API 키는 보안 저장소에만',
            'AI 서비스의 API 키는 iOS Keychain / Android Keystore 에만 저장됩니다. '
                '백업 파일에도, 로그에도 포함되지 않습니다.',
          ),
          section(
            '권한',
            '· 카메라 · 사진: 영수증을 첨부할 때만 사용합니다.\n'
                '· 알림: 정비 알림을 켰을 때만 요청합니다.\n\n'
                '위치 권한은 요청하지 않습니다.',
          ),
          section(
            '수집하지 않는 것',
            '사용 기록, 광고 식별자, 위치, 연락처를 수집하지 않습니다. 분석 도구를 넣지 '
                '않았습니다.',
          ),
        ],
      ),
    );
  }
}
