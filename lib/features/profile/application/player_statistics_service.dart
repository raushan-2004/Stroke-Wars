import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/profile/domain/models/player_statistics.dart';

part 'player_statistics_service.g.dart';

/// Service responsible for computing stats for display in the UI.
@riverpod
class PlayerStatisticsService extends _$PlayerStatisticsService {
  @override
  void build() {}

  /// Computes the win rate percentage.
  double calculateWinRate(PlayerStatistics stats) {
    if (stats.gamesPlayed == 0) return 0.0;
    return (stats.wins / stats.gamesPlayed) * 100.0;
  }

  /// Computes average guess time in seconds.
  double? calculateAverageGuessTime(PlayerStatistics stats) {
    if (stats.wordsGuessed == 0 || stats.totalGuessTime == null) {
      return null;
    }
    return stats.totalGuessTime! / stats.wordsGuessed;
  }

  /// Computes level progress fraction (0.0 to 1.0) based on xp in current level.
  double calculateXpProgress(PlayerStatistics stats) {
    final nextLevelXp = stats.level * 1000;
    if (nextLevelXp == 0) return 0.0;
    final progress = stats.xp / nextLevelXp;
    return progress.clamp(0.0, 1.0);
  }

  /// Returns total XP needed to clear the current level.
  int getXpThreshold(int level) {
    return level * 1000;
  }
}
