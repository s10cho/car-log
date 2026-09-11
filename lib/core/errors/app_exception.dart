/// Base class for failures this app raises deliberately.
///
/// Repositories translate plugin- and driver-specific errors into these so the
/// presentation layer never has to know about Drift or platform channels.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// The local database could not be read or written.
class LocalDatabaseException extends AppException {
  const LocalDatabaseException(super.message, {super.cause, super.stackTrace});
}

/// Keychain / Keystore backed storage failed.
class SecureStorageException extends AppException {
  const SecureStorageException(super.message, {super.cause, super.stackTrace});
}

/// A receipt file could not be stored, read or removed.
class ReceiptStorageException extends AppException {
  const ReceiptStorageException(super.message, {super.cause, super.stackTrace});
}

/// A call to an AI provider failed.
///
/// Carries a message meant for the user: the analysis is optional, so the app
/// says what went wrong and lets them type the record in by hand.
class AiProviderException extends AppException {
  const AiProviderException(
    super.message, {
    this.isCredentialProblem = false,
    super.cause,
    super.stackTrace,
  });

  /// Whether the key is wrong or rejected, which the user can fix in settings.
  final bool isCredentialProblem;
}
