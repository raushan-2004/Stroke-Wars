import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/production/domain/models/production_models.dart';
import 'package:stroke_wars/features/production/application/logging_service.dart';
import 'package:stroke_wars/features/production/application/analytics_service.dart';
import 'package:stroke_wars/features/production/application/crash_reporting_service.dart';
import 'package:stroke_wars/features/production/application/performance_monitor.dart';
import 'package:stroke_wars/features/production/application/diagnostics_center.dart';
import 'package:stroke_wars/features/production/application/environment_manager.dart';
import 'package:stroke_wars/features/production/application/release_validator.dart';
import 'package:stroke_wars/features/production/application/security_manager.dart';
import 'package:stroke_wars/features/production/application/accessibility_manager.dart';
import 'package:stroke_wars/features/production/application/localization_manager.dart';

void main() {
  group('Production Readiness, Performance & Release (Stage 12) — Integration Tests', () {
    late LoggingService loggingService;
    late MockAnalyticsService analyticsService;
    late MockCrashReportingService crashReportingService;
    late PerformanceMonitor performanceMonitor;
    late DiagnosticsCenter diagnosticsCenter;
    late EnvironmentManager environmentManager;
    late ReleaseValidator releaseValidator;
    late SecurityManager securityManager;
    late AccessibilityManager accessibilityManager;
    late LocalizationManager localizationManager;

    setUp(() {
      loggingService = LoggingService();
      analyticsService = MockAnalyticsService();
      crashReportingService = MockCrashReportingService();
      performanceMonitor = PerformanceMonitor();
      diagnosticsCenter = DiagnosticsCenter(
        analytics: analyticsService,
        crashReporting: crashReportingService,
        performance: performanceMonitor,
        logs: loggingService,
      );
      environmentManager = EnvironmentManager();
      releaseValidator = ReleaseValidator();
      securityManager = SecurityManager();
      accessibilityManager = AccessibilityManager();
      localizationManager = LocalizationManager();
    });

    test('EnvironmentManager switches and loads configurations correctly', () {
      expect(environmentManager.currentEnv, equals(SWEnvironment.development));
      expect(environmentManager.currentConfig.apiEndpoint, contains('dev.strokewars.local'));

      // Switch to Production
      environmentManager.switchEnvironment(SWEnvironment.production);
      expect(environmentManager.currentEnv, equals(SWEnvironment.production));
      expect(environmentManager.currentConfig.apiEndpoint, equals('https://api.strokewars.com'));
      expect(environmentManager.isFeatureEnabled('experimental_brush'), isFalse);
    });

    test('LoggingService filters credentials, emails, and auth keys successfully', () {
      loggingService.info('User input: test@strokewars.com');
      loggingService.warning('Token: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ');
      loggingService.error('password=secret123');

      final logs = loggingService.logs;
      expect(logs, hasLength(3));

      expect(logs[0].message, contains('[EMAIL_REDACTED]'));
      expect(logs[0].isRedacted, isTrue);

      expect(logs[1].message, contains('[AUTH_REDACTED]'));
      expect(logs[1].isRedacted, isTrue);

      expect(logs[2].message, contains('password: [SENSITIVE_REDACTED]'));
      expect(logs[2].isRedacted, isTrue);
    });

    test('DiagnosticsCenter aggregates analytics and handles failures', () {
      diagnosticsCenter.trackAppStarted();
      expect(analyticsService.events.first.name, equals('AppStarted'));
      expect(loggingService.logs.first.message, contains('Application initialized'));

      final testError = StateError('Test panic');
      diagnosticsCenter.reportFailure('Fatal runtime crash', testError, StackTrace.current);

      expect(crashReportingService.reports, hasLength(1));
      expect(crashReportingService.reports.first['error'], contains('Test panic'));
    });

    test('ReleaseValidator audits production settings, locales, and assets', () {
      // 1. Valid Configuration
      final validConfig = const ReleaseConfiguration(
        environment: SWEnvironment.production,
        apiEndpoint: 'https://api.strokewars.com',
        featureFlags: {'experimental_brush': false},
        analyticsEnabled: true,
        crashReportingEnabled: true,
        buildFlavor: 'prod',
      );

      final report = releaseValidator.validateProductionReady(
        validConfig,
        locales: ['en', 'es'],
        assets: ['assets/images'],
      );
      expect(report.isValid, isTrue);
      expect(report.errors, isEmpty);

      // 2. Invalid Configuration (Non-https endpoint, crash reporting disabled in production, missing English fallback)
      final invalidConfig = const ReleaseConfiguration(
        environment: SWEnvironment.production,
        apiEndpoint: 'http://dev.strokewars.local/api',
        featureFlags: {'experimental_brush': true},
        analyticsEnabled: false,
        crashReportingEnabled: false,
        buildFlavor: 'prod',
      );

      final failReport = releaseValidator.validateProductionReady(
        invalidConfig,
        locales: ['es'],
        assets: [],
      );
      expect(failReport.isValid, isFalse);
      expect(failReport.errors, hasLength(5)); // https, dev domain, crash reporting disabled, missing fallback locale, empty assets
    });

    test('SecurityManager abstraction verification hashes and secure stores', () {
      // Secure Storage Encryption Mock
      securityManager.writeSecure('session_token', 'SW_SESSION_9988');
      final val = securityManager.readSecure('session_token');
      expect(val, equals('SW_SESSION_9988'));

      // Replay integrity checksum
      const rawPayload = '{"matchId":"m-1","events":[]}';
      final expectedHash = sha256.convert(utf8.encode(rawPayload)).toString();
      expect(securityManager.verifyReplayIntegrity(rawPayload, expectedHash), isTrue);

      // Root, Emulator, Screenshot Protection defaults
      expect(securityManager.detectJailbreak(), isFalse);
      expect(securityManager.detectEmulator(), isFalse);
      expect(securityManager.isScreenshotProtectionEnabled(), isTrue);
    });

    test('AccessibilityManager checks touch sizes and WCAG compliance', () {
      expect(accessibilityManager.verifyTouchTargetSize(48.0, 48.0), isTrue);
      expect(accessibilityManager.verifyTouchTargetSize(40.0, 48.0), isFalse);

      expect(accessibilityManager.verifyContrastCompliance(5.5), isTrue);
      expect(accessibilityManager.verifyContrastCompliance(3.2), isFalse);
    });

    test('LocalizationManager handles Spanish conversions and fallback behaviors', () {
      // Default: English
      expect(localizationManager.translate('app_title'), equals('Stroke Wars'));

      // Plurals conversion
      expect(localizationManager.translatePlural('many_players', 1), equals('1 Player'));
      expect(localizationManager.translatePlural('many_players', 5), equals('5 Players'));

      // Switch Locale
      localizationManager.switchLocale('es');
      expect(localizationManager.translate('app_title'), equals('Guerra de Trazos'));
      expect(localizationManager.translatePlural('many_players', 5), equals('5 Jugadores'));

      // Missing Translation fallback to English
      expect(localizationManager.translate('lobby_title'), equals('Sala LAN')); // Translated in Spanish
      localizationManager.switchLocale('es');
      expect(localizationManager.translate('missing_translated_key'), equals('missing_translated_key'));
    });
  });
}
