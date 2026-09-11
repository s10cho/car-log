import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/errors/app_exception.dart';

/// How long to wait before giving up on a provider.
///
/// Reading an image takes a provider a few seconds; a minute means something
/// is wrong and the user is better served by falling back to typing.
const Duration aiRequestTimeout = Duration(seconds: 45);

/// Sends a request with a timeout and one retry.
///
/// One retry, not a loop: a second failure is information, and an app that
/// keeps retrying burns the user's data and their provider quota while showing
/// a spinner. Only transient conditions are retried — a rejected key will be
/// rejected again.
Future<http.Response> sendAiRequest(
  Future<http.Response> Function() send, {
  required String providerName,
  Duration timeout = aiRequestTimeout,
}) async {
  Future<http.Response> attempt() => send().timeout(timeout);

  try {
    final response = await attempt();
    if (_isTransient(response.statusCode)) {
      return await attempt();
    }
    return response;
  } on TimeoutException catch (error, stackTrace) {
    throw AiProviderException(
      '$providerName 응답이 너무 오래 걸립니다. 잠시 후 다시 시도하거나 직접 입력해 주세요.',
      cause: error,
      stackTrace: stackTrace,
    );
  } on SocketException catch (error, stackTrace) {
    throw AiProviderException(
      '네트워크에 연결할 수 없습니다. 직접 입력해 주세요.',
      cause: error,
      stackTrace: stackTrace,
    );
  } on http.ClientException catch (error, stackTrace) {
    throw AiProviderException(
      '$providerName 에 연결하지 못했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

bool _isTransient(int statusCode) =>
    statusCode == 429 || (statusCode >= 500 && statusCode < 600);

/// Turns a non-200 answer into a message the user can act on.
///
/// The response body is deliberately not included: it can quote the receipt
/// back, and receipts are personal.
void ensureAiSuccess(http.Response response, {required String providerName}) {
  if (response.statusCode == 200) {
    return;
  }

  final message = switch (response.statusCode) {
    401 || 403 => '$providerName 키가 거부되었습니다. 설정에서 키를 확인해 주세요.',
    429 => '$providerName 사용량 한도에 걸렸습니다. 잠시 후 다시 시도해 주세요.',
    >= 500 => '$providerName 서버에 문제가 있습니다. 잠시 후 다시 시도해 주세요.',
    _ => '$providerName 분석에 실패했습니다 (${response.statusCode}).',
  };

  throw AiProviderException(
    message,
    isCredentialProblem:
        response.statusCode == 401 || response.statusCode == 403,
  );
}

/// Decodes a model's answer, tolerating the fence it sometimes wraps JSON in.
Map<String, Object?> decodeAiJson(String text) {
  var cleaned = text.trim();
  if (cleaned.startsWith('```')) {
    cleaned = cleaned
        .replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '')
        .replaceFirst(RegExp(r'```$'), '')
        .trim();
  }

  try {
    final decoded = jsonDecode(cleaned);
    return decoded is Map<String, Object?> ? decoded : const {};
  } on FormatException {
    // A model that answered in prose has told us nothing usable; an empty
    // draft leaves every field for the user rather than inventing values.
    return const {};
  }
}

/// The MIME type to declare for an image being uploaded.
String lookupImageMimeType(String path) =>
    switch (p.extension(path).toLowerCase()) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.heic' || '.heif' => 'image/heic',
      _ => 'image/jpeg',
    };
