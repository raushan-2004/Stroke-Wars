import 'package:stroke_wars/features/production/application/analytics_service.dart';
import 'package:stroke_wars/features/production/application/crash_reporting_service.dart';
import 'package:stroke_wars/features/production/application/performance_monitor.dart';
import 'package:stroke_wars/features/production/application/logging_service.dart';

/// Single unified entry point coordinating all telemetry, crashes, and diagnostics.
class DiagnosticsCenter {
  final AnalyticsService analytics;
  final CrashReportingService crashReporting;
  final PerformanceMonitor performance;
  final LoggingService logs;

  const DiagnosticsCenter({
    required this.analytics,
    required this.crashReporting,
    required this.performance,
    required this.logs,
  });

  /// Logs app started milestone event.
  void trackAppStarted() {
    logs.info('DiagnosticsCenter: Application initialized.');
    analytics.trackEvent('AppStarted');
    performance.recordMetric('startup_time_ms', 450.0);
  }

  /// Unified failure logging: registers warning/error and dumps details to the crash reporter.
  void reportFailure(String summary, dynamic error, StackTrace? stack) {
    logs.error('Failure: $summary - Error: $error');
    crashReporting.recordError(error, stack, reason: summary);
  }
}
