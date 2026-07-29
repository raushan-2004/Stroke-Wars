import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_settings.freezed.dart';
part 'player_settings.g.dart';

/// Player settings preferences for accessibility and customizability.
@freezed
class PlayerSettings with _$PlayerSettings {
  /// Creates a [PlayerSettings].
  const factory PlayerSettings({
    required String themeMode,
    required String accentColor,
    required bool soundEnabled,
    required bool hapticsEnabled,
    required bool reduceMotion,
    required String animationSpeed,
  }) = _PlayerSettings;

  /// Creates a [PlayerSettings] from JSON map.
  factory PlayerSettings.fromJson(Map<String, dynamic> json) =>
      _$PlayerSettingsFromJson(json);

  /// Default starting player settings configuration.
  factory PlayerSettings.initial() => const PlayerSettings(
    themeMode: 'system',
    accentColor: 'purple',
    soundEnabled: true,
    hapticsEnabled: true,
    reduceMotion: false,
    animationSpeed: 'medium',
  );
}
