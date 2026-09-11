import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../domain/ai_provider.dart';
import '../domain/receipt_analysis.dart';
import 'ai_http.dart';

/// Google Gemini, via the Generative Language API.
class GeminiProvider implements AiProvider {
  GeminiProvider({http.Client? client, String? model})
    : _client = client ?? http.Client(),
      _model = model ?? 'gemini-2.5-flash';

  final http.Client _client;
  final String _model;

  static const String _base =
      'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get id => 'gemini';

  @override
  String get displayName => 'Google Gemini';

  @override
  String get credentialHelpUrl => 'https://aistudio.google.com/app/apikey';

  @override
  Future<bool> validateCredential(String apiKey) async {
    // Listing models is the cheapest call that still proves the key works.
    final response = await sendAiRequest(
      () => _client.get(
        Uri.parse('$_base/models'),
        headers: {'x-goog-api-key': apiKey},
      ),
      providerName: displayName,
    );
    return response.statusCode == 200;
  }

  @override
  Future<ReceiptAnalysis> analyzeReceipt({
    required File image,
    required String apiKey,
    required List<String> knownItems,
  }) async {
    final bytes = await image.readAsBytes();
    final response = await sendAiRequest(
      () => _client.post(
        Uri.parse('$_base/models/$_model:generateContent'),
        headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': receiptPrompt(knownItems)},
                {
                  'inline_data': {
                    'mime_type': lookupImageMimeType(image.path),
                    'data': base64Encode(bytes),
                  },
                },
              ],
            },
          ],
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      ),
      providerName: displayName,
    );

    ensureAiSuccess(response, providerName: displayName);

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final text = _firstText(body);
    if (text == null) {
      throw const AiProviderException('영수증에서 읽어낸 내용이 없습니다.');
    }
    return parseReceiptAnalysis(decodeAiJson(text));
  }

  String? _firstText(Map<String, Object?> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }
    final content = (candidates.first as Map<String, Object?>)['content'];
    final parts = (content as Map<String, Object?>?)?['parts'];
    if (parts is! List || parts.isEmpty) {
      return null;
    }
    return (parts.first as Map<String, Object?>)['text'] as String?;
  }
}
