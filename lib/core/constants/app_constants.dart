/// Application-wide constant values.
abstract final class AppConstants {
  /// App display name used across UI.
  static const String appName = 'Stroke Wars';

  /// Default HTTP request timeout.
  static const Duration httpTimeout = Duration(seconds: 30);

  /// Default debounce duration for search/input.
  static const Duration debounceDuration = Duration(milliseconds: 350);

  /// Hive preferences box name.
  static const String preferencesBoxName = 'preferences';

  /// Hive cache box name.
  static const String cacheBoxName = 'cache';

  /// Preference keys stored in Hive.
  static const String themePreferenceKey = 'theme_mode';

  /// Key for whether user completed onboarding.
  static const String onboardingCompletedKey = 'onboarding_completed';

  /// Key for player name.
  static const String playerNameKey = 'player_name';

  /// Key for player avatar URL.
  static const String playerAvatarUrlKey = 'player_avatar_url';

  /// Key for player data JSON object.
  static const String playerKey = 'player_data';
}
