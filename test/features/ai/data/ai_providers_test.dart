import 'dart:convert';
import 'dart:io';

import 'package:car_log/core/errors/app_exception.dart';
import 'package:car_log/features/ai/data/gemini_provider.dart';
import 'package:car_log/features/ai/data/openai_provider.dart';
import 'package:car_log/features/ai/domain/ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

void main() {
  late File receipt;
  late List<http.Request> sent;

  setUp(() {
    final directory = Directory.systemTemp.createTempSync('car_log_ai');
    addTearDown(() => directory.deleteSync(recursive: true));
    receipt = File(p.join(directory.path, 'receipt.jpg'))
      ..writeAsBytesSync([1, 2, 3, 4]);
    sent = [];
  });

  http.Client clientReturning(String body, {int status = 200}) {
    return MockClient((request) async {
      sent.add(request);
      return http.Response(
        body,
        status,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
  }

  String geminiBody(String text) => jsonEncode({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
      },
    ],
  });

  String openAiBody(String text) => jsonEncode({
    'choices': [
      {
        'message': {'content': text},
      },
    ],
  });

  const answer =
      '{"date":"2026-02-01","shop_name":"동네카센터","cost":80000,'
      '"mileage":33000,"maintenance_item":"엔진오일"}';

  group('Gemini', () {
    test('reads a receipt into a draft', () async {
      final provider = GeminiProvider(
        client: clientReturning(geminiBody(answer)),
      );

      final analysis = await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'k',
        knownItems: const ['엔진오일'],
      );

      expect(analysis.date, DateTime(2026, 2, 1));
      expect(analysis.shopName, '동네카센터');
      expect(analysis.cost, 80000);
      expect(analysis.mileage, 33000);
      expect(analysis.maintenanceTypeName, '엔진오일');
    });

    test('sends the key in a header, never in the URL', () async {
      final provider = GeminiProvider(
        client: clientReturning(geminiBody(answer)),
      );

      await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'secret-key',
        knownItems: const [],
      );

      expect(sent.single.headers['x-goog-api-key'], 'secret-key');
      expect(sent.single.url.toString(), isNot(contains('secret-key')));
    });

    test('sends the known items so it answers with one of them', () async {
      final provider = GeminiProvider(
        client: clientReturning(geminiBody(answer)),
      );

      await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'k',
        knownItems: const ['엔진오일', '와이퍼'],
      );

      expect(sent.single.body, contains('와이퍼'));
    });

    test('a rejected key surfaces as a credential problem', () async {
      final provider = GeminiProvider(
        client: clientReturning('{}', status: 401),
      );

      expect(
        () => provider.analyzeReceipt(
          image: receipt,
          apiKey: 'bad',
          knownItems: const [],
        ),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.isCredentialProblem,
            'isCredentialProblem',
            isTrue,
          ),
        ),
      );
    });

    test('an answer with no candidates is reported, not guessed at', () async {
      final provider = GeminiProvider(client: clientReturning('{}'));

      expect(
        () => provider.analyzeReceipt(
          image: receipt,
          apiKey: 'k',
          knownItems: const [],
        ),
        throwsA(isA<AiProviderException>()),
      );
    });

    test('validateCredential is true only for a 200', () async {
      expect(
        await GeminiProvider(client: clientReturning('{}'))
            .validateCredential('k'),
        isTrue,
      );
      expect(
        await GeminiProvider(client: clientReturning('{}', status: 403))
            .validateCredential('k'),
        isFalse,
      );
    });
  });

  group('OpenAI', () {
    test('reads a receipt into a draft', () async {
      final provider = OpenAiProvider(
        client: clientReturning(openAiBody(answer)),
      );

      final analysis = await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'k',
        knownItems: const ['엔진오일'],
      );

      expect(analysis.cost, 80000);
      expect(analysis.maintenanceTypeName, '엔진오일');
    });

    test('sends the key as a bearer token', () async {
      final provider = OpenAiProvider(
        client: clientReturning(openAiBody(answer)),
      );

      await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'secret-key',
        knownItems: const [],
      );

      expect(sent.single.headers['Authorization'], 'Bearer secret-key');
    });

    test('sends the image inline as a data URL', () async {
      final provider = OpenAiProvider(
        client: clientReturning(openAiBody(answer)),
      );

      await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'k',
        knownItems: const [],
      );

      expect(sent.single.body, contains('data:image/jpeg;base64,'));
    });

    test('a fenced answer is still read', () async {
      final provider = OpenAiProvider(
        client: clientReturning(openAiBody('```json\n$answer\n```')),
      );

      final analysis = await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'k',
        knownItems: const [],
      );

      expect(analysis.cost, 80000);
    });

    test('an answer in prose yields an empty draft, not an error', () async {
      final provider = OpenAiProvider(
        client: clientReturning(openAiBody('영수증이 흐릿해 읽을 수 없습니다.')),
      );

      final analysis = await provider.analyzeReceipt(
        image: receipt,
        apiKey: 'k',
        knownItems: const [],
      );

      expect(analysis.isEmpty, isTrue);
    });
  });

  test('every provider declares where to get a key', () {
    for (final AiProvider provider in [GeminiProvider(), OpenAiProvider()]) {
      expect(provider.id, isNotEmpty);
      expect(provider.displayName, isNotEmpty);
      expect(provider.credentialHelpUrl, startsWith('https://'));
    }
  });
}
