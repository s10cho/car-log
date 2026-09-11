import 'package:car_log/core/storage/secure_store.dart';

/// Stands in for the Keychain / Keystore in tests.
///
/// The real store goes through a platform channel that a widget test has no
/// implementation for, so anything reading a credential would hang.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
