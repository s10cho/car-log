import 'package:car_log/features/garage/domain/milestone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GarageStats stats({
    int recordCount = 0,
    int trackedItemCount = 0,
    int mileage = 0,
    int overdueCount = 0,
    int vehicleCount = 1,
    bool hasReceipt = false,
  }) => GarageStats(
    recordCount: recordCount,
    trackedItemCount: trackedItemCount,
    catalogueSize: 10,
    mileage: mileage,
    overdueCount: overdueCount,
    vehicleCount: vehicleCount,
    hasReceipt: hasReceipt,
  );

  Milestone find(List<Milestone> all, String id) =>
      all.firstWhere((m) => m.id.startsWith(id));

  test('a brand new garage has nothing achieved', () {
    final milestones = buildMilestones(stats());

    expect(milestones.where((m) => m.achieved), isEmpty);
    // 잠긴 배지도 보여 준다 — 다음에 무엇을 하면 되는지 알려 주는 게 목적이다.
    expect(milestones, isNotEmpty);
  });

  test('the first record unlocks the first badge', () {
    final milestones = buildMilestones(stats(recordCount: 1));

    expect(find(milestones, 'first_record').achieved, isTrue);
    expect(find(milestones, 'records_10').achieved, isFalse);
  });

  test('ten records unlocks the next one', () {
    final milestones = buildMilestones(stats(recordCount: 10));

    expect(find(milestones, 'records_10').achieved, isTrue);
  });

  test('attaching a receipt unlocks its badge', () {
    expect(find(buildMilestones(stats()), 'receipt_kept').achieved, isFalse);
    expect(
      find(buildMilestones(stats(hasReceipt: true)), 'receipt_kept').achieved,
      isTrue,
    );
  });

  test('tracking five items unlocks the toolbox', () {
    expect(
      find(
        buildMilestones(stats(trackedItemCount: 4)),
        'tracking_five',
      ).achieved,
      isFalse,
    );
    expect(
      find(
        buildMilestones(stats(trackedItemCount: 5)),
        'tracking_five',
      ).achieved,
      isTrue,
    );
  });

  group('all clear', () {
    test('needs something tracked to mean anything', () {
      // 아무것도 기록하지 않은 상태는 "전부 정상" 이 아니다.
      expect(find(buildMilestones(stats()), 'all_clear').achieved, isFalse);
    });

    test('is earned when nothing is overdue', () {
      final milestones = buildMilestones(
        stats(trackedItemCount: 3, overdueCount: 0),
      );

      expect(find(milestones, 'all_clear').achieved, isTrue);
    });

    test('is lost while anything is overdue', () {
      final milestones = buildMilestones(
        stats(trackedItemCount: 3, overdueCount: 1),
      );

      expect(find(milestones, 'all_clear').achieved, isFalse);
    });
  });

  group('distance marks', () {
    test('only the next one is shown while it is out of reach', () {
      final milestones = buildMilestones(stats(mileage: 3000));
      final mileage = find(milestones, 'mileage_');

      expect(mileage.id, 'mileage_10000');
      expect(mileage.achieved, isFalse);
      expect(
        milestones.where((m) => m.id.startsWith('mileage_')),
        hasLength(1),
        reason: '12,000 km 인 사람에게 다섯 개를 늘어놓지 않는다',
      );
    });

    test('the highest reached mark is shown once passed', () {
      final mileage = find(buildMilestones(stats(mileage: 120000)), 'mileage_');

      expect(mileage.id, 'mileage_100000');
      expect(mileage.achieved, isTrue);
      expect(mileage.label, '10만 km');
    });

    test('the description reads with separators', () {
      final mileage = find(buildMilestones(stats(mileage: 55000)), 'mileage_');

      expect(mileage.description, contains('50,000 km'));
    });

    test('past the last mark it stays on the last mark', () {
      final mileage = find(buildMilestones(stats(mileage: 900000)), 'mileage_');

      expect(mileage.id, 'mileage_300000');
      expect(mileage.achieved, isTrue);
    });
  });

  test('a second vehicle unlocks the garage badge', () {
    expect(find(buildMilestones(stats()), 'two_vehicles').achieved, isFalse);
    expect(
      find(buildMilestones(stats(vehicleCount: 2)), 'two_vehicles').achieved,
      isTrue,
    );
  });

  test('every milestone has something to show', () {
    for (final milestone in buildMilestones(stats())) {
      expect(milestone.label, isNotEmpty);
      expect(milestone.description, isNotEmpty);
      expect(milestone.emoji, isNotEmpty);
    }
  });
}
