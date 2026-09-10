import 'package:intl/intl.dart';

/// Numeric-only patterns on purpose: they read the same in every locale, so
/// the app does not have to ship and initialise locale date symbols.
final DateFormat _date = DateFormat('yyyy.MM.dd');
final NumberFormat _thousands = NumberFormat('#,###');

String formatDate(DateTime date) => _date.format(date);

String formatKilometres(int km) => '${_thousands.format(km)} km';

String formatWon(int won) => '${_thousands.format(won)}원';

/// "1,200 km 남음" / "300 km 초과" — the sign is carried by the word, not a
/// minus, because "-300 km 남음" reads as a puzzle.
String formatRemainingDistance(int km) => km >= 0
    ? '${_thousands.format(km)} km 남음'
    : '${_thousands.format(-km)} km 초과';

String formatRemainingDays(int days) {
  if (days >= 0) {
    return '$days일 남음';
  }
  return '${-days}일 지남';
}
