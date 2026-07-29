import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement.freezed.dart';
part 'achievement.g.dart';

/// Static definition for an in-game achievement.
@freezed
class AchievementDefinition with _$AchievementDefinition {
  /// Creates an [AchievementDefinition].
  const factory AchievementDefinition({
    required String id,
    required String title,
    required String description,
    required int points,
  }) = _AchievementDefinition;

  /// Creates an [AchievementDefinition] from JSON map.
  factory AchievementDefinition.fromJson(Map<String, dynamic> json) =>
      _$AchievementDefinitionFromJson(json);
}

/// Tracking model for a player's achievement progress.
@freezed
class AchievementProgress with _$AchievementProgress {
  /// Creates an [AchievementProgress].
  const factory AchievementProgress({
    required String achievementId,
    required bool isUnlocked,
    required DateTime? unlockedAt,
    required int currentProgress,
    required int targetProgress,
  }) = _AchievementProgress;

  /// Creates an [AchievementProgress] from JSON map.
  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      _$AchievementProgressFromJson(json);
}
