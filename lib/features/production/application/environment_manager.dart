import 'package:stroke_wars/features/production/domain/models/production_models.dart';

/// Centralized manager resolving and caching ReleaseConfigurations across target deployment flavors.
class EnvironmentManager {
  SWEnvironment _currentEnv = SWEnvironment.development;
  late ReleaseConfiguration _currentConfig;

  EnvironmentManager() {
    _loadConfigFor(_currentEnv);
  }

  ReleaseConfiguration get currentConfig => _currentConfig;
  SWEnvironment get currentEnv => _currentEnv;

  /// Changes the active environment and loads the associated configuration presets.
  void switchEnvironment(SWEnvironment env) {
    _currentEnv = env;
    _loadConfigFor(env);
  }

  void _loadConfigFor(SWEnvironment env) {
    switch (env) {
      case SWEnvironment.development:
        _currentConfig = const ReleaseConfiguration(
          environment: SWEnvironment.development,
          apiEndpoint: 'https://dev.strokewars.local/api',
          featureFlags: {
            'holiday_theme': false,
            'experimental_brush': true,
            'maintenance_mode': false,
          },
          analyticsEnabled: false,
          crashReportingEnabled: false,
          buildFlavor: 'dev',
        );
        break;
      case SWEnvironment.staging:
        _currentConfig = const ReleaseConfiguration(
          environment: SWEnvironment.staging,
          apiEndpoint: 'https://staging.strokewars.local/api',
          featureFlags: {
            'holiday_theme': true,
            'experimental_brush': true,
            'maintenance_mode': false,
          },
          analyticsEnabled: true,
          crashReportingEnabled: true,
          buildFlavor: 'staging',
        );
        break;
      case SWEnvironment.production:
        _currentConfig = const ReleaseConfiguration(
          environment: SWEnvironment.production,
          apiEndpoint: 'https://api.strokewars.com',
          featureFlags: {
            'holiday_theme': false,
            'experimental_brush': false,
            'maintenance_mode': false,
          },
          analyticsEnabled: true,
          crashReportingEnabled: true,
          buildFlavor: 'prod',
        );
        break;
    }
  }

  /// Evaluates if a given feature flag is active under the current configuration.
  bool isFeatureEnabled(String flagKey) {
    return _currentConfig.featureFlags[flagKey] ?? false;
  }
}
