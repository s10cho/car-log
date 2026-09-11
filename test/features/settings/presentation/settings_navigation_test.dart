import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  Future<void> openSettings(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp().app);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await settle(tester);
  }

  testWidgets('every settings entry opens its screen', (tester) async {
    await openSettings(tester);

    for (final (entry, marker) in const [
      ('알림', '정비 알림'),
      ('차량 연동', '연동되지 않음'),
      ('AI 영수증 분석', 'API 키는 이 기기의 보안 저장소'),
      ('정비 항목', '기본 주기는 일반적인 권장값입니다'),
      ('백업 / 복원', '백업 내보내기'),
      ('개인정보 처리방침', '데이터는 기기에 있습니다'),
      ('앱 정보', '오픈소스 라이선스'),
    ]) {
      await tester.tap(find.widgetWithText(ListTile, entry));
      await settle(tester);
      expect(
        find.textContaining(marker),
        findsWidgets,
        reason: '"$entry" 를 열면 "$marker" 가 보여야 한다',
      );

      await tester.tap(find.byType(BackButton));
      await settle(tester);
    }
  });

  testWidgets('the privacy policy says nothing leaves without the user', (
    tester,
  ) async {
    await openSettings(tester);
    await tester.tap(find.widgetWithText(ListTile, '개인정보 처리방침'));
    await settle(tester);

    expect(find.textContaining('계정도, 로그인도, 저희 서버도 없습니다'), findsOneWidget);
    expect(find.textContaining('위치 권한은 요청하지 않습니다'), findsOneWidget);
    expect(find.textContaining('백업 파일에도, 로그에도 포함되지 않습니다'), findsOneWidget);
  });
}
