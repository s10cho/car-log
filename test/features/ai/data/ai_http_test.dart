import 'dart:io';

import 'package:car_log/core/errors/app_exception.dart';
import 'package:car_log/features/ai/data/ai_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('decoding a model answer', () {
    test('reads plain JSON', () {
      expect(decodeAiJson('{"cost": 1000}'), {'cost': 1000});
    });

    test('unwraps a fenced block', () {
      expect(decodeAiJson('```json\n{"cost": 1000}\n```'), {'cost': 1000});
      expect(decodeAiJson('```\n{"cost": 1000}\n```'), {'cost': 1000});
    });

    test('an answer in prose yields nothing rather than throwing', () {
      expect(decodeAiJson('영수증을 읽을 수 없습니다.'), isEmpty);
    });

    test('a JSON array is not an answer', () {
      expect(decodeAiJson('[1, 2, 3]'), isEmpty);
    });
  });

  group('mapping a failure to a message', () {
    void expectMessage(int status, Matcher matcher) {
      expect(
        () => ensureAiSuccess(
          http.Response('{"error":"x"}', status),
          providerName: 'TestAI',
        ),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.message,
            'message',
            matcher,
          ),
        ),
      );
    }

    test('200 passes', () {
      expect(
        () => ensureAiSuccess(http.Response('{}', 200), providerName: 'TestAI'),
        returnsNormally,
      );
    });

    test('401 points at the key', () {
      expectMessage(401, contains('키'));
      expect(
        () => ensureAiSuccess(http.Response('', 401), providerName: 'TestAI'),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.isCredentialProblem,
            'isCredentialProblem',
            isTrue,
          ),
        ),
      );
    });

    test('429 says to wait', () {
      expectMessage(429, contains('한도'));
    });

    test('500 blames the provider', () {
      expectMessage(500, contains('서버'));
    });

    test('the response body never reaches the user', () {
      // 본문에는 영수증 내용이 인용될 수 있다.
      expect(
        () => ensureAiSuccess(
          http.Response(
            '{"error":"동네카센터 영수증"}',
            400,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
          providerName: 'TestAI',
        ),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.message,
            'message',
            isNot(contains('동네카센터')),
          ),
        ),
      );
    });
  });

  group('sending', () {
    test('returns a success straight through', () async {
      var calls = 0;
      final response = await sendAiRequest(() async {
        calls++;
        return http.Response('ok', 200);
      }, providerName: 'TestAI');

      expect(response.statusCode, 200);
      expect(calls, 1);
    });

    test('retries once on a transient failure, then gives up', () async {
      var calls = 0;
      final response = await sendAiRequest(() async {
        calls++;
        return http.Response('busy', 503);
      }, providerName: 'TestAI');

      expect(calls, 2, reason: '한 번만 재시도한다');
      expect(response.statusCode, 503);
    });

    test('does not retry a rejected key', () async {
      var calls = 0;
      await sendAiRequest(() async {
        calls++;
        return http.Response('nope', 401);
      }, providerName: 'TestAI');

      expect(calls, 1);
    });

    test('a timeout becomes a message about trying again or typing', () async {
      expect(
        () => sendAiRequest(
          () => Future<http.Response>.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('late', 200),
          ),
          providerName: 'TestAI',
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.message,
            'message',
            contains('직접 입력'),
          ),
        ),
      );
    });

    test('being offline says so', () {
      expect(
        () => sendAiRequest(
          () => throw const SocketException('offline'),
          providerName: 'TestAI',
        ),
        throwsA(
          isA<AiProviderException>().having(
            (e) => e.message,
            'message',
            contains('네트워크'),
          ),
        ),
      );
    });
  });

  group('image mime types', () {
    test('maps the extensions the pickers produce', () {
      expect(lookupImageMimeType('/tmp/a.png'), 'image/png');
      expect(lookupImageMimeType('/tmp/a.HEIC'), 'image/heic');
      expect(lookupImageMimeType('/tmp/a.webp'), 'image/webp');
    });

    test('falls back to jpeg', () {
      expect(lookupImageMimeType('/tmp/a.jpg'), 'image/jpeg');
      expect(lookupImageMimeType('/tmp/a.unknown'), 'image/jpeg');
    });
  });
}
