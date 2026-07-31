import 'package:stroke_wars/features/production/domain/models/production_models.dart';

/// Evaluation result from validation checks.
class ValidationReport {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationReport({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// System auditor validating release readiness across endpoints, localizations, and flags.
class ReleaseValidator {
  /// Asserts release configurations for a production deployment.
  ValidationReport validateProductionReady(
    ReleaseConfiguration config, {
    required List<String> locales,
    required List<String> assets,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Endpoint Checks
    if (config.environment == SWEnvironment.production) {
      if (!config.apiEndpoint.startsWith('https://')) {
        errors.add('Production endpoint must utilize secure https connection!');
      }
      if (config.apiEndpoint.contains('local') || config.apiEndpoint.contains('dev')) {
        errors.add('Production configuration points to local/test endpoint: ${config.apiEndpoint}');
      }
    }

    // 2. Telemetry and Crashes
    if (config.environment == SWEnvironment.production) {
      if (!config.analyticsEnabled) {
        warnings.add('Analytics is disabled under production config!');
      }
      if (!config.crashReportingEnabled) {
        errors.add('Crash reporting must be active for production configurations!');
      }
    }

    // 3. Localization audits
    if (locales.isEmpty) {
      errors.add('No localized language packs found!');
    } else {
      if (!locales.contains('en')) {
        errors.add('English fallback locale mapping is missing!');
      }
    }

    // 4. Asset checks
    if (assets.isEmpty) {
      errors.add('No asset directories resolved!');
    }

    // 5. Feature Flags Audits
    if (config.environment == SWEnvironment.production) {
      // In production, debug mode settings should not be enabled
      if (config.featureFlags['experimental_brush'] == true) {
        warnings.add('Experimental brush features remain active in production!');
      }
    }

    return ValidationReport(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}
