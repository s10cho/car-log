import 'dart:io';

import 'receipt_analysis.dart';

/// An AI service that can read a receipt.
///
/// The maintenance feature never names a provider. Adding one means adding an
/// implementation here and listing it in `availableAiProviders`; nothing in the
/// domain or the UI changes.
abstract interface class AiProvider {
  /// Stable identifier, used as the secure-storage key suffix.
  String get id;

  String get displayName;

  /// Where the user gets a key, shown next to the input.
  String get credentialHelpUrl;

  /// Checks a key without spending a full analysis.
  Future<bool> validateCredential(String apiKey);

  /// Reads [image] and returns what it found.
  ///
  /// [knownItems] are the maintenance items this app knows about, so the
  /// provider can answer with one of them rather than inventing a name.
  Future<ReceiptAnalysis> analyzeReceipt({
    required File image,
    required String apiKey,
    required List<String> knownItems,
  });
}

/// What the app asks a provider to do, in words.
///
/// Kept in one place so every provider is asked the same question and their
/// answers can be parsed the same way.
String receiptPrompt(List<String> knownItems) =>
    '''
이 이미지는 자동차 정비 영수증입니다. 아래 JSON 형식으로만 답하세요. 설명을 덧붙이지 마세요.

{
  "date": "YYYY-MM-DD",
  "shop_name": "정비소 이름",
  "cost": 숫자만 (원),
  "mileage": 숫자만 (km),
  "maintenance_item": "정비 항목",
  "memo": "특이사항"
}

규칙:
- 영수증에서 확인할 수 없는 값은 반드시 null 로 두세요. 추측하지 마세요.
- cost 와 mileage 는 쉼표나 단위 없이 숫자만 쓰세요.
- maintenance_item 은 가능하면 다음 중 하나를 그대로 쓰세요: ${knownItems.join(', ')}
- 해당하는 것이 없으면 영수증에 적힌 표현을 그대로 쓰세요.
''';
