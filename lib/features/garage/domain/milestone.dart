import 'package:meta/meta.dart';

/// Something worth noticing that the user has reached.
///
/// Deliberately about the car and the habit, not about using the app: a badge
/// for "opened the app 7 days running" rewards the wrong thing. These mark
/// real events — a first record kept, a hundred thousand kilometres driven.
@immutable
class Milestone {
  const Milestone({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
    required this.achieved,
  });

  final String id;
  final String label;
  final String description;
  final String emoji;
  final bool achieved;
}

/// What the app measures milestones against.
@immutable
class GarageStats {
  const GarageStats({
    required this.recordCount,
    required this.trackedItemCount,
    required this.catalogueSize,
    required this.mileage,
    required this.overdueCount,
    required this.vehicleCount,
    required this.hasReceipt,
  });

  final int recordCount;
  final int trackedItemCount;
  final int catalogueSize;
  final int mileage;
  final int overdueCount;
  final int vehicleCount;
  final bool hasReceipt;
}

/// Distance marks worth celebrating, in kilometres.
const List<int> mileageMilestones = [10000, 50000, 100000, 200000, 300000];

/// Builds the badge list, achieved and not.
///
/// Unachieved ones are returned too: a locked badge says what to do next,
/// which is the point. Only the next distance mark is included — showing all
/// five to someone at 12,000 km is noise.
List<Milestone> buildMilestones(GarageStats stats) {
  final nextMileage = mileageMilestones.firstWhere(
    (mark) => stats.mileage < mark,
    orElse: () => mileageMilestones.last,
  );
  final reachedMileage = mileageMilestones
      .where((mark) => stats.mileage >= mark)
      .toList();
  final mileageMark = reachedMileage.isEmpty
      ? nextMileage
      : reachedMileage.last;

  return [
    Milestone(
      id: 'first_record',
      label: '첫 기록',
      description: '정비 기록을 처음 남겼습니다',
      emoji: '🔧',
      achieved: stats.recordCount >= 1,
    ),
    Milestone(
      id: 'records_10',
      label: '기록 10건',
      description: '정비 기록 10건을 모았습니다',
      emoji: '📒',
      achieved: stats.recordCount >= 10,
    ),
    Milestone(
      id: 'receipt_kept',
      label: '영수증 보관',
      description: '영수증을 기록에 첨부했습니다',
      emoji: '🧾',
      achieved: stats.hasReceipt,
    ),
    Milestone(
      id: 'tracking_five',
      label: '5개 항목 관리',
      description: '서로 다른 정비 항목 5개를 기록했습니다',
      emoji: '🧰',
      achieved: stats.trackedItemCount >= 5,
    ),
    Milestone(
      id: 'all_clear',
      label: '전부 정상',
      description: '교체 시기를 지난 항목이 없습니다',
      emoji: '✨',
      achieved: stats.trackedItemCount > 0 && stats.overdueCount == 0,
    ),
    Milestone(
      id: 'mileage_$mileageMark',
      label: '${(mileageMark / 10000).round()}만 km',
      description: '${_thousands(mileageMark)} km 를 함께 달렸습니다',
      emoji: '🛣️',
      achieved: stats.mileage >= mileageMark,
    ),
    Milestone(
      id: 'two_vehicles',
      label: '차고 확장',
      description: '차량 2대 이상을 관리합니다',
      emoji: '🏠',
      achieved: stats.vehicleCount >= 2,
    ),
  ];
}

String _thousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
