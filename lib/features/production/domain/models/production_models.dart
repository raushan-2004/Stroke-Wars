enum SWEnvironment { development, staging, production }

/// Production release configuration schema.
class ReleaseConfiguration {
  final SWEnvironment environment;
  final String apiEndpoint;
  final Map<String, bool> featureFlags;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final String buildFlavor;

  const ReleaseConfiguration({
    required this.environment,
    required this.apiEndpoint,
    required this.featureFlags,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
    required this.buildFlavor,
  });
}

/// Feature flag value tracker.
class FeatureFlag {
  final String key;
  final bool value;
  final String description;

  const FeatureFlag({
    required this.key,
    required this.value,
    required this.description,
  });
}

/// Analytics logging events structure.
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });
}

/// System logging message.
class LogMessage {
  final DateTime timestamp;
  final String level; // 'DEBUG', 'INFO', 'WARN', 'ERROR'
  final String message;
  final bool isRedacted;

  const LogMessage({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.isRedacted,
  });
}
