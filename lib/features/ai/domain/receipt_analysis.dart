import 'package:meta/meta.dart';

/// What an AI provider read off a receipt.
///
/// Every field is optional: a receipt may not show the odometer, the shop name
/// may be unreadable, and a provider that guesses to fill the shape would be
/// worse than one that admits it did not find something.
///
/// This is a **draft**. Nothing here reaches the database until the user has
/// looked at it — see `docs/decisions.md`.
@immutable
class ReceiptAnalysis {
  const ReceiptAnalysis({
    this.date,
    this.shopName,
    this.cost,
    this.mileage,
    this.maintenanceTypeName,
    this.memo,
  });

  final DateTime? date;
  final String? shopName;
  final int? cost;
  final int? mileage;

  /// The item as the provider named it, matched against the catalogue by the
  /// caller rather than trusted as an id.
  final String? maintenanceTypeName;

  final String? memo;

  /// Whether the provider found anything at all worth showing.
  bool get isEmpty =>
      date == null &&
      shopName == null &&
      cost == null &&
      mileage == null &&
      maintenanceTypeName == null;

  /// The fields that were filled, for telling the user what came from the AI.
  Set<ReceiptField> get filledFields => {
    if (date != null) ReceiptField.date,
    if (mileage != null) ReceiptField.mileage,
    if (cost != null) ReceiptField.cost,
    if (shopName != null) ReceiptField.shopName,
    if (maintenanceTypeName != null) ReceiptField.maintenanceType,
    if (memo != null) ReceiptField.memo,
  };

  @override
  String toString() =>
      'ReceiptAnalysis(date: $date, type: $maintenanceTypeName, '
      'mileage: $mileage, cost: $cost, shop: $shopName)';
}

/// Fields an analysis can fill, used to mark them in the form.
enum ReceiptField { date, mileage, cost, shopName, maintenanceType, memo }

/// Parses a provider's JSON answer into an analysis.
///
/// Providers are told to return this shape, but they are language models: a
/// missing key, a string where a number was asked for, or a date in the wrong
/// format are all expected. Anything unparseable becomes null rather than an
/// error — a partly read receipt is still useful.
ReceiptAnalysis parseReceiptAnalysis(Map<String, Object?> json) {
  return ReceiptAnalysis(
    date: _parseDate(json['date']),
    shopName: _parseText(json['shop_name']),
    cost: _parseInt(json['cost']),
    mileage: _parseInt(json['mileage']),
    maintenanceTypeName: _parseText(json['maintenance_item']),
    memo: _parseText(json['memo']),
  );
}

String? _parseText(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  // Models often answer "unknown" or "N/A" instead of omitting the key.
  if (trimmed.isEmpty ||
      const {
        'unknown',
        'n/a',
        'na',
        'null',
        '없음',
        '미상',
      }.contains(trimmed.toLowerCase())) {
    return null;
  }
  return trimmed;
}

int? _parseInt(Object? value) {
  final parsed = switch (value) {
    final int number => number,
    final double number => number.round(),
    // "1,234", "12,000원", "33000 km" all show up in practice.
    final String text => int.tryParse(text.replaceAll(RegExp(r'[^0-9-]'), '')),
    _ => null,
  };
  return (parsed == null || parsed < 0) ? null : parsed;
}

DateTime? _parseDate(Object? value) {
  if (value is! String) {
    return null;
  }
  final normalised = value.trim().replaceAll(RegExp(r'[./]'), '-');
  final parsed = DateTime.tryParse(normalised);
  if (parsed == null) {
    return null;
  }
  // A receipt from the future is a misread, not a receipt.
  final today = DateTime.now();
  if (parsed.isAfter(DateTime(today.year, today.month, today.day))) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}
