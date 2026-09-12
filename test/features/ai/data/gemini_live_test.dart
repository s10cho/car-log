import 'dart:io';
import 'dart:typed_data';

import 'package:car_log/features/ai/data/gemini_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Calls the real Gemini API.
///
/// Skipped unless a key is supplied, so the suite stays offline by default:
///
///     flutter test test/features/ai/data/gemini_live_test.dart \
///       --dart-define=GEMINI_API_KEY=...
///
/// The mocked tests cover request shape and error mapping. These exist for what
/// mocks cannot check — that the endpoint and model the app ships with are
/// still live, and that a real receipt is actually read. A pinned model quietly
/// retiring is exactly how this breaks in the wild.
void main() {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final skip = apiKey.isEmpty ? 'GEMINI_API_KEY 를 주면 실행된다' : null;

  /// A synthetic Korean workshop receipt, checked in so this verifies real
  /// extraction rather than only that the endpoint answers.
  final receipt = File('test/support/assets/sample_receipt.jpg');

  test('reads the fields off a real receipt image', () async {
    final analysis = await GeminiProvider().analyzeReceipt(
      image: receipt,
      apiKey: apiKey,
      knownItems: const ['엔진오일', '오일필터', '에어컨필터', '와이퍼', '타이어'],
    );

    expect(analysis.date, DateTime(2026, 8, 14));
    expect(analysis.mileage, 47250);
    expect(analysis.cost, 106000);
    expect(analysis.shopName, contains('스피드카센터'));
    // 항목은 우리가 준 목록 안에서 답해야 한다.
    expect(const [
      '엔진오일',
      '오일필터',
      '에어컨필터',
    ], contains(analysis.maintenanceTypeName));
  }, skip: skip);

  test('a blank image reads as nothing rather than invented values', () async {
    final analysis = await GeminiProvider().analyzeReceipt(
      image: _writeBlankImage(),
      apiKey: apiKey,
      knownItems: const ['엔진오일'],
    );

    expect(analysis.isEmpty, isTrue);
  }, skip: skip);

  test('validates the key', () async {
    expect(await GeminiProvider().validateCredential(apiKey), isTrue);
  }, skip: skip);
}

/// A blank JPEG, for checking the model admits when there is nothing to read.
File _writeBlankImage() {
  final directory = Directory.systemTemp.createTempSync('car_log_live');
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  final file = File('${directory.path}/blank.jpg');
  file.writeAsBytesSync(_blankJpeg);
  return file;
}

/// 1x1 white JPEG.
final Uint8List _blankJpeg = Uint8List.fromList([
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0x00,
  0x10,
  0x4A,
  0x46,
  0x49,
  0x46,
  0x00,
  0x01,
  0x01,
  0x00,
  0x00,
  0x01,
  0x00,
  0x01,
  0x00,
  0x00,
  0xFF,
  0xDB,
  0x00,
  0x43,
  0x00,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xFF,
  0xC0,
  0x00,
  0x0B,
  0x08,
  0x00,
  0x01,
  0x00,
  0x01,
  0x01,
  0x01,
  0x11,
  0x00,
  0xFF,
  0xC4,
  0x00,
  0x14,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x03,
  0xFF,
  0xC4,
  0x00,
  0x14,
  0x10,
  0x01,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0xFF,
  0xDA,
  0x00,
  0x08,
  0x01,
  0x01,
  0x00,
  0x00,
  0x3F,
  0x00,
  0xD2,
  0xCF,
  0x20,
  0xFF,
  0xD9,
]);
