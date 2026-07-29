/// Application-wide environment configuration.
///
/// Provides a centralized place for build-time constants and feature flags.
/// Extend this as the project grows with environment-specific overrides.
abstract final class AppConfig {
  /// Application display name.
  static const String appName = 'Stroke Wars';

  /// Maximum players per room.
  static const int maxPlayersPerRoom = 8;

  /// Minimum players required to start a game.
  static const int minPlayersToStart = 2;

  /// Default round duration in seconds.
  static const int defaultRoundDurationSeconds = 80;

  /// Default number of rounds per game.
  static const int defaultRoundCount = 3;

  /// API base URL (production). Replace with environment variable in CI/CD.
  static const String apiBaseUrl = 'https://api.strokewars.app/v1';

  /// WebSocket base URL (production).
  static const String wsBaseUrl = 'wss://ws.strokewars.app/v1';

  /// Whether verbose logging is enabled.
  /// Should be false in production builds.
  static const bool verboseLogging = bool.fromEnvironment('VERBOSE_LOGGING');

  /// Whether to use mock data instead of real network calls.
  static const bool useMockData = bool.fromEnvironment('USE_MOCK_DATA');
}
