import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../domain/ai_provider.dart';
import '../domain/receipt_analysis.dart';
import 'ai_http.dart';

/// OpenAI, via the chat completions API.
class OpenAiProvider implements AiProvider {
  OpenAiProvider({http.Client? client, String? model})
    : _client = client ?? http.Client(),
      _model = model ?? 'gpt-4.1-mini';

  final http.Client _client;
  final String _model;

  static const String _base = 'https://api.openai.com/v1';

  @override
  String get id => 'openai';

  @override
  String get displayName => 'OpenAI';

  @override
  String get credentialHelpUrl => 'https://platform.openai.com/api-keys';

  @override
  Future<bool> validateCredential(String apiKey) async {
    final response = await sendAiRequest(
      () => _client.get(
        Uri.parse('$_base/models'),
        headers: {'Authorization': 'Bearer $apiKey'},
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
    final dataUrl =
        'data:${lookupImageMimeType(image.path)};base64,${base64Encode(bytes)}';

    final response = await sendAiRequest(
      () => _client.post(
        Uri.parse('$_base/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': receiptPrompt(knownItems)},
                {
                  'type': 'image_url',
                  'image_url': {'url': dataUrl},
                },
              ],
            },
          ],
        }),
      ),
      providerName: displayName,
    );

    ensureAiSuccess(response, providerName: displayName);

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const AiProviderException('영수증에서 읽어낸 내용이 없습니다.');
    }
    final message =
        (choices.first as Map<String, Object?>)['message']
            as Map<String, Object?>?;
    final text = message?['content'] as String?;
    if (text == null) {
      throw const AiProviderException('영수증에서 읽어낸 내용이 없습니다.');
    }
    return parseReceiptAnalysis(decodeAiJson(text));
  }
}
