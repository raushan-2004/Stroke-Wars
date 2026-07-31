/// Interface for publishing crash dumps, stack traces, and session crumbs.
abstract interface class CrashReportingService {
  void recordError(dynamic error, StackTrace? stackTrace, {dynamic reason});
  void recordNonFatal(String message, {Map<String, dynamic>? details});
  void setUser(String userId);
  void setCustomKey(String key, dynamic value);
  void leaveBreadcrumb(String message);
  List<String> get breadcrumbs;
}

/// Simulated locally stateful Crash Reporter.
class MockCrashReportingService implements CrashReportingService {
  final List<String> _breadcrumbs = [];
  final List<Map<String, dynamic>> _reports = [];
  String? _userId;
  final Map<String, dynamic> _customKeys = {};

  @override
  List<String> get breadcrumbs => List.unmodifiable(_breadcrumbs);
  List<Map<String, dynamic>> get reports => List.unmodifiable(_reports);
  String? get userId => _userId;
  Map<String, dynamic> get customKeys => Map.unmodifiable(_customKeys);

  @override
  void recordError(dynamic error, StackTrace? stackTrace, {dynamic reason}) {
    _reports.add({
      'type': 'FATAL',
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'reason': reason?.toString(),
      'breadcrumbs': List<String>.from(_breadcrumbs),
      'userId': _userId,
      'keys': Map<String, dynamic>.from(_customKeys),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void recordNonFatal(String message, {Map<String, dynamic>? details}) {
    _reports.add({
      'type': 'NON_FATAL',
      'message': message,
      'details': details,
      'breadcrumbs': List<String>.from(_breadcrumbs),
      'userId': _userId,
      'keys': Map<String, dynamic>.from(_customKeys),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  void setUser(String userId) {
    _userId = userId;
  }

  @override
  void setCustomKey(String key, dynamic value) {
    _customKeys[key] = value;
  }

  @override
  void leaveBreadcrumb(String message) {
    _breadcrumbs.add(message);
    if (_breadcrumbs.length > 50) {
      _breadcrumbs.removeAt(0); // Cap size
    }
  }

  void clear() {
    _breadcrumbs.clear();
    _reports.clear();
    _userId = null;
    _customKeys.clear();
  }
}
