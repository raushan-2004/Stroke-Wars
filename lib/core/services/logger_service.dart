import 'package:logger/logger.dart';

/// Centralized logging service for Stroke Wars.
///
/// Wraps the `logger` package with structured log levels.
/// Use [AppLogger.instance] to access the singleton throughout the app.
/// Inject via Riverpod providers for testability.
final class AppLogger {
  AppLogger._() {
    _logger = Logger(
      printer: PrettyPrinter(
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: _AppLogFilter(),
      output: MultiOutput([ConsoleOutput()]),
    );
  }

  /// The singleton instance of [AppLogger].
  static final AppLogger instance = AppLogger._();

  late final Logger _logger;

  /// Logs a verbose/trace message.
  void trace(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a debug message.
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Logs an informational message.
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a warning.
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Logs an error.
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a fatal / wtf error.
  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Custom log filter — suppresses verbose logs in production.
final class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release builds, only show warnings and above.
    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}
