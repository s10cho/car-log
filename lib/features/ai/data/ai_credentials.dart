import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/storage/secure_store.dart';
import '../../settings/data/app_preferences_repository.dart';
import '../domain/ai_provider.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';

/// Which provider the user picked. Null means AI is switched off.
const String selectedAiProviderKey = 'ai_provider';

/// Whether the user has agreed to receipts leaving the device.
const String aiConsentKey = 'ai_upload_consent';

/// The providers this build knows about.
final aiProvidersProvider = Provider<List<AiProvider>>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return [GeminiProvider(client: client), OpenAiProvider(client: client)];
});

/// Stores provider API keys and the user's choice of provider.
///
/// Keys go to the Keychain / Keystore and nowhere else: not in Drift, not in
/// preferences, not in an export backup, not in a log line.
class AiCredentials {
  const AiCredentials(this._secure, this._preferences, this._providers);

  final SecureStore _secure;
  final AppPreferencesRepository _preferences;
  final List<AiProvider> _providers;

  String _keyFor(String providerId) => 'ai_api_key_$providerId';

  Future<String?> apiKeyFor(String providerId) =>
      _secure.read(_keyFor(providerId));

  Future<void> saveApiKey(String providerId, String apiKey) =>
      _secure.write(_keyFor(providerId), apiKey);

  Future<void> removeApiKey(String providerId) async {
    await _secure.delete(_keyFor(providerId));
    if (await selectedProviderId() == providerId) {
      await clearSelection();
    }
  }

  Future<String?> selectedProviderId() =>
      _preferences.read(selectedAiProviderKey);

  Future<void> select(String providerId) =>
      _preferences.write(selectedAiProviderKey, providerId);

  Future<void> clearSelection() => _preferences.remove(selectedAiProviderKey);

  Stream<String?> watchSelectedProviderId() =>
      _preferences.watch(selectedAiProviderKey);

  Future<bool> hasConsented() async =>
      await _preferences.read(aiConsentKey) == 'true';

  Future<void> recordConsent() => _preferences.write(aiConsentKey, 'true');

  /// The provider that is both chosen and holds a key, or null.
  ///
  /// Both halves matter: a provider selected but missing its key would fail on
  /// the first analysis, and the button should simply not offer itself.
  Future<({AiProvider provider, String apiKey})?> readyProvider() async {
    final id = await selectedProviderId();
    if (id == null) {
      return null;
    }

    final provider = _providers.where((p) => p.id == id).firstOrNull;
    if (provider == null) {
      return null;
    }

    final apiKey = await apiKeyFor(id);
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    return (provider: provider, apiKey: apiKey);
  }
}

final aiCredentialsProvider = Provider<AiCredentials>(
  (ref) => AiCredentials(
    ref.watch(secureStoreProvider),
    ref.watch(appPreferencesRepositoryProvider),
    ref.watch(aiProvidersProvider),
  ),
);

/// The provider the record form should offer, if any.
final readyAiProviderProvider =
    StreamProvider<({AiProvider provider, String apiKey})?>((ref) async* {
      final credentials = ref.watch(aiCredentialsProvider);
      yield await credentials.readyProvider();
      await for (final _ in credentials.watchSelectedProviderId().skip(1)) {
        yield await credentials.readyProvider();
      }
    });
