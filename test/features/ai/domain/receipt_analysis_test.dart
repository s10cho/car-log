import 'package:car_log/features/ai/domain/receipt_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReceiptAnalysis parse(Map<String, Object?> json) =>
      parseReceiptAnalysis(json);

  group('numbers', () {
    test('accepts a plain integer', () {
      expect(parse({'cost': 80000}).cost, 80000);
    });

    test('strips separators and units a model leaves in', () {
      expect(parse({'cost': '80,000원'}).cost, 80000);
      expect(parse({'mileage': '33 000 km'}).mileage, 33000);
    });

    test('rounds a decimal', () {
      expect(parse({'cost': 79999.6}).cost, 80000);
    });

    test('rejects a negative value', () {
      expect(parse({'cost': -5000}).cost, isNull);
    });

    test('gives up on text with no digits', () {
      expect(parse({'cost': '확인 불가'}).cost, isNull);
    });
  });

  group('text', () {
    test('trims', () {
      expect(parse({'shop_name': '  동네카센터 '}).shopName, '동네카센터');
    });

    test('treats a model stand-in for missing as missing', () {
      for (final value in ['unknown', 'N/A', 'null', '없음', '']) {
        expect(
          parse({'shop_name': value}).shopName,
          isNull,
          reason: 'value was "$value"',
        );
      }
    });

    test('ignores a non-string', () {
      expect(parse({'shop_name': 42}).shopName, isNull);
    });
  });

  group('dates', () {
    test('reads an ISO date', () {
      expect(parse({'date': '2026-02-01'}).date, DateTime(2026, 2, 1));
    });

    test('reads dots and slashes', () {
      expect(parse({'date': '2026.02.01'}).date, DateTime(2026, 2, 1));
      expect(parse({'date': '2026/02/01'}).date, DateTime(2026, 2, 1));
    });

    test('drops the time of day', () {
      expect(parse({'date': '2026-02-01T13:45:00'}).date, DateTime(2026, 2, 1));
    });

    test('rejects a date in the future as a misread', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final text =
          '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}'
          '-${tomorrow.day.toString().padLeft(2, '0')}';

      expect(parse({'date': text}).date, isNull);
    });

    test('rejects nonsense', () {
      expect(parse({'date': '지난주 화요일'}).date, isNull);
    });
  });

  group('the whole answer', () {
    test('an empty object yields an empty analysis', () {
      expect(parse(const {}).isEmpty, isTrue);
    });

    test('one filled field is not empty', () {
      expect(parse({'cost': 1000}).isEmpty, isFalse);
    });

    test('reports which fields were filled', () {
      final analysis = parse({
        'date': '2026-02-01',
        'cost': 80000,
        'shop_name': '동네카센터',
      });

      expect(analysis.filledFields, {
        ReceiptField.date,
        ReceiptField.cost,
        ReceiptField.shopName,
      });
    });

    test('a partly readable receipt still gives what it could', () {
      final analysis = parse({
        'date': '2026-02-01',
        'shop_name': 'unknown',
        'cost': '80,000',
        'mileage': null,
        'maintenance_item': '엔진오일',
      });

      expect(analysis.date, DateTime(2026, 2, 1));
      expect(analysis.shopName, isNull);
      expect(analysis.cost, 80000);
      expect(analysis.mileage, isNull);
      expect(analysis.maintenanceTypeName, '엔진오일');
    });
  });
}
