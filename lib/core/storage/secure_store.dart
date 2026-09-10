import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/app_exception.dart';

/// Keychain (iOS) / Keystore-backed storage (Android) for credentials only.
///
/// AI API keys, OAuth access and refresh tokens live here and nowhere else:
/// not in Drift, not in shared preferences, and never inside an export backup.
class SecureStore {
  const SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Object catch (error, stackTrace) {
      throw SecureStorageException(
        'Failed to read secure value for "$key"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on Object catch (error, stackTrace) {
      throw SecureStorageException(
        'Failed to write secure value for "$key"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on Object catch (error, stackTrace) {
      throw SecureStorageException(
        'Failed to delete secure value for "$key"',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final secureStoreProvider = Provider<SecureStore>(
  (ref) => const SecureStore(
    FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  ),
);
