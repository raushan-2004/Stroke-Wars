import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/features/production/application/analytics_service.dart';
import 'package:stroke_wars/features/production/application/crash_reporting_service.dart';
import 'package:stroke_wars/features/production/application/performance_monitor.dart';
import 'package:stroke_wars/features/production/application/logging_service.dart';
import 'package:stroke_wars/features/production/application/diagnostics_center.dart';
import 'package:stroke_wars/features/production/application/environment_manager.dart';
import 'package:stroke_wars/features/production/application/release_validator.dart';
import 'package:stroke_wars/features/production/application/security_manager.dart';
import 'package:stroke_wars/features/production/application/accessibility_manager.dart';
import 'package:stroke_wars/features/production/application/localization_manager.dart';

part 'production_providers.g.dart';

@riverpod
LoggingService loggingService(LoggingServiceRef ref) => LoggingService();

@riverpod
AnalyticsService analyticsService(AnalyticsServiceRef ref) =>
    MockAnalyticsService();

@riverpod
CrashReportingService crashReportingService(CrashReportingServiceRef ref) =>
    MockCrashReportingService();

@riverpod
PerformanceMonitor performanceMonitor(PerformanceMonitorRef ref) =>
    PerformanceMonitor();

@riverpod
DiagnosticsCenter diagnosticsCenter(DiagnosticsCenterRef ref) {
  return DiagnosticsCenter(
    analytics: ref.watch(analyticsServiceProvider),
    crashReporting: ref.watch(crashReportingServiceProvider),
    performance: ref.watch(performanceMonitorProvider),
    logs: ref.watch(loggingServiceProvider),
  );
}

@riverpod
EnvironmentManager environmentManager(EnvironmentManagerRef ref) =>
    EnvironmentManager();

@riverpod
ReleaseValidator releaseValidator(ReleaseValidatorRef ref) =>
    ReleaseValidator();

@riverpod
SecurityManager securityManager(SecurityManagerRef ref) => SecurityManager();

@riverpod
AccessibilityManager accessibilityManager(AccessibilityManagerRef ref) =>
    AccessibilityManager();

@riverpod
LocalizationManager localizationManager(LocalizationManagerRef ref) =>
    LocalizationManager();
