import 'dart:io';

import 'package:car_log/features/ai/domain/ai_provider.dart';
import 'package:car_log/features/ai/domain/receipt_analysis.dart';

/// Stands in for a real AI service in widget tests.
class FakeAiProvider implements AiProvider {
  FakeAiProvider({this.id = 'fake', this.displayName = 'Fake AI'});

  @override
  final String id;

  @override
  final String displayName;

  @override
  String get credentialHelpUrl => 'https://example.test/keys';

  /// What the next analysis returns.
  ReceiptAnalysis result = const ReceiptAnalysis();

  /// When set, analysis throws this instead.
  Object? error;

  bool credentialIsValid = true;
  int analyzeCalls = 0;
  List<String> lastKnownItems = const [];

  @override
  Future<bool> validateCredential(String apiKey) async => credentialIsValid;

  @override
  Future<ReceiptAnalysis> analyzeReceipt({
    required File image,
    required String apiKey,
    required List<String> knownItems,
  }) async {
    analyzeCalls++;
    lastKnownItems = knownItems;
    if (error != null) {
      throw error!;
    }
    return result;
  }
}
