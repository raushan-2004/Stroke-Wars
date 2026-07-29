/// Base class for all application-specific exceptions.
///
/// Provides a consistent error contract across the codebase.
/// All domain and infrastructure exceptions should extend this class.
sealed class AppException implements Exception {
  /// Base constructor for [AppException].
  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Human-readable error description.
  final String message;

  /// Machine-readable error code for logging/analytics.
  final String? code;

  /// The original underlying error if this wraps another exception.
  final Object? originalError;

  /// Stack trace associated with the error.
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Thrown when a network operation fails.
final class NetworkException extends AppException {
  /// Creates a [NetworkException].
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
    super.stackTrace,
    this.statusCode,
  });

  /// HTTP status code if available.
  final int? statusCode;
}

/// Thrown when local storage operations fail.
final class StorageException extends AppException {
  /// Creates a [StorageException].
  const StorageException({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when runtime permissions are denied.
final class PermissionException extends AppException {
  /// Creates a [PermissionException].
  const PermissionException({
    required super.message,
    super.code = 'PERMISSION_DENIED',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when a feature or resource is not found.
final class NotFoundException extends AppException {
  /// Creates a [NotFoundException].
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown when authentication or authorization fails.
final class AuthException extends AppException {
  /// Creates an [AuthException].
  const AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Thrown for unexpected / unclassified errors.
final class UnexpectedException extends AppException {
  /// Creates an [UnexpectedException].
  const UnexpectedException({
    required super.message,
    super.code = 'UNEXPECTED_ERROR',
    super.originalError,
    super.stackTrace,
  });
}
