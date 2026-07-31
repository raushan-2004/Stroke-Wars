import 'package:stroke_wars/features/production/domain/models/production_models.dart';

/// Centralized logging manager filtering logs and removing sensitive parameters.
class LoggingService {
  final List<LogMessage> _logs = [];
  final List<void Function(LogMessage)> _listeners = [];

  List<LogMessage> get logs => List.unmodifiable(_logs);

  void addListener(void Function(LogMessage) listener) =>
      _listeners.add(listener);
  void removeListener(void Function(LogMessage) listener) =>
      _listeners.remove(listener);

  /// Filters logs to remove credentials or keys.
  String filterSensitiveData(String msg) {
    // Regex matches common API keys, passwords, bearer tokens, or emails
    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );
    final authRegex = RegExp(
      r'(Bearer\s+[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*)',
    );
    final passwordRegex = RegExp(
      r'(password|key|token|secret)\s*[:=]\s*[^\[\s,]+',
      caseSensitive: false,
    );

    var filtered = msg;
    if (emailRegex.hasMatch(filtered)) {
      filtered = filtered.replaceAll(emailRegex, '[EMAIL_REDACTED]');
    }
    if (authRegex.hasMatch(filtered)) {
      filtered = filtered.replaceAll(authRegex, '[AUTH_REDACTED]');
    }
    if (passwordRegex.hasMatch(filtered)) {
      filtered = filtered.replaceAllMapped(passwordRegex, (match) {
        return '${match.group(1)}: [SENSITIVE_REDACTED]';
      });
    }
    return filtered;
  }

  void debug(String msg) => _log('DEBUG', msg);
  void info(String msg) => _log('INFO', msg);
  void warning(String msg) => _log('WARN', msg);
  void error(String msg) => _log('ERROR', msg);

  void _log(String level, String msg) {
    final filteredMsg = filterSensitiveData(msg);
    final isRedacted = filteredMsg != msg;

    final log = LogMessage(
      timestamp: DateTime.now(),
      level: level,
      message: filteredMsg,
      isRedacted: isRedacted,
    );

    _logs.add(log);
    for (final listener in _listeners) {
      listener(log);
    }
  }

  void clearLogs() => _logs.clear();
}
