import 'package:car_log/core/errors/app_exception.dart';
import 'package:car_log/features/ai/domain/receipt_analysis.dart';
import 'package:car_log/features/vehicle/data/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_receipt_picker.dart';
import '../../../support/test_app.dart';

void main() {
  /// Opens the record form with a receipt already attached.
  Future<ProviderContainer> formWithReceipt(
    WidgetTester tester, {
    bool withAi = true,
  }) async {
    final (:app, :container) = buildTestApp();
    await container
        .read(vehicleRepositoryProvider)
        .create(displayName: '아반떼', currentMileage: 32000);
    if (withAi) {
      await connectFakeAi(container);
    }

    await tester.pumpWidget(app);
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);

    pickerOf(container).next = FakeReceiptPicker.fileNamed('receipt.jpg');
    await tester.tap(find.widgetWithText(OutlinedButton, '영수증 첨부'));
    await settle(tester);
    await tester.tap(find.text('앨범에서 선택'));
    await settle(tester);

    return container;
  }

  Future<void> analyze(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Fake AI 로 분석'));
    await settle(tester);
  }

  Future<void> agreeAndAnalyze(WidgetTester tester) async {
    await analyze(tester);
    await tester.tap(find.widgetWithText(FilledButton, '동의하고 분석'));
    await settle(tester);
  }

  group('when nothing is connected', () {
    testWidgets('no analyse button is offered', (tester) async {
      await formWithReceipt(tester, withAi: false);

      expect(find.textContaining('분석'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '영수증 첨부'), findsNothing);
      expect(find.text('receipt.jpg'), findsOneWidget);
    });
  });

  group('consent', () {
    testWidgets('is asked before the first receipt leaves the device', (
      tester,
    ) async {
      final container = await formWithReceipt(tester);

      await analyze(tester);

      expect(find.text('영수증을 AI 로 보낼까요?'), findsOneWidget);
      expect(aiOf(container).analyzeCalls, 0, reason: '동의 전에는 보내지 않는다');
    });

    testWidgets('declining leaves the form untouched', (tester) async {
      final container = await formWithReceipt(tester);

      await analyze(tester);
      await tester.tap(find.widgetWithText(TextButton, '직접 입력'));
      await settle(tester);

      expect(aiOf(container).analyzeCalls, 0);
      expect(find.text('Fake AI 로 분석'), findsOneWidget);
    });

    testWidgets('is asked only once', (tester) async {
      final container = await formWithReceipt(tester);
      aiOf(container).result = const ReceiptAnalysis(cost: 1000);

      await agreeAndAnalyze(tester);
      await analyze(tester);

      expect(find.text('영수증을 AI 로 보낼까요?'), findsNothing);
      expect(aiOf(container).analyzeCalls, 2);
    });
  });

  group('a successful analysis', () {
    testWidgets('fills the form but saves nothing', (tester) async {
      final container = await formWithReceipt(tester);
      aiOf(container).result = const ReceiptAnalysis(
        date: null,
        shopName: '동네카센터',
        cost: 80000,
        mileage: 33000,
      );

      await agreeAndAnalyze(tester);

      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
            )
            .controller
            ?.text,
        '33000',
      );
      // 정비소 칸은 화면 아래에 있어 스크롤해야 보인다.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await settle(tester);
      expect(find.text('동네카센터'), findsWidgets);
      // 아직 저장 화면을 떠나지 않았다.
      expect(find.widgetWithText(FilledButton, '저장'), findsOneWidget);
    });

    testWidgets('marks the fields it filled', (tester) async {
      final container = await formWithReceipt(tester);
      aiOf(container).result = const ReceiptAnalysis(cost: 80000);

      await agreeAndAnalyze(tester);

      expect(find.text('AI 가 채운 값입니다. 확인해 주세요.'), findsWidgets);
    });

    testWidgets('passes the catalogue so it answers with a known item', (
      tester,
    ) async {
      final container = await formWithReceipt(tester);
      aiOf(container).result = const ReceiptAnalysis(cost: 1);

      await agreeAndAnalyze(tester);

      expect(aiOf(container).lastKnownItems, contains('엔진오일'));
      expect(aiOf(container).lastKnownItems, contains('와이퍼'));
    });

    testWidgets('an item it names is selected in the picker', (tester) async {
      final container = await formWithReceipt(tester);
      aiOf(container).result = const ReceiptAnalysis(
        maintenanceTypeName: '와이퍼',
      );

      await agreeAndAnalyze(tester);

      expect(find.text('와이퍼'), findsWidgets);
    });

    testWidgets('an item it invents is ignored', (tester) async {
      final container = await formWithReceipt(tester);
      aiOf(container).result = const ReceiptAnalysis(
        maintenanceTypeName: '터보차저 교체',
      );

      await agreeAndAnalyze(tester);

      expect(find.text('터보차저 교체'), findsNothing);
      expect(find.text('엔진오일'), findsWidgets, reason: '기본 선택이 유지된다');
    });

    testWidgets('an empty answer says so and leaves the form alone', (
      tester,
    ) async {
      final container = await formWithReceipt(tester);
      aiOf(container).result = const ReceiptAnalysis();

      await agreeAndAnalyze(tester);

      expect(find.text('영수증에서 읽어낸 내용이 없습니다. 직접 입력해 주세요.'), findsOneWidget);
    });
  });

  group('a failed analysis', () {
    testWidgets('shows the provider message and keeps the form usable', (
      tester,
    ) async {
      final container = await formWithReceipt(tester);
      aiOf(container).error = const AiProviderException(
        'Fake AI 키가 거부되었습니다. 설정에서 키를 확인해 주세요.',
        isCredentialProblem: true,
      );

      await agreeAndAnalyze(tester);

      expect(find.textContaining('키가 거부되었습니다'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '저장'), findsOneWidget);
    });

    testWidgets('an unexpected failure still falls back to typing', (
      tester,
    ) async {
      final container = await formWithReceipt(tester);
      aiOf(container).error = StateError('boom');

      await agreeAndAnalyze(tester);

      expect(find.text('영수증을 분석하지 못했습니다. 직접 입력해 주세요.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '정비 시 주행거리 (km)'),
        '33000',
      );
      await tapAndAwaitIo(tester, find.widgetWithText(FilledButton, '저장'));

      expect(find.text('33,000 km'), findsWidgets);
    });
  });
}
