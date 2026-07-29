import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/domain/models/achievement.dart';
import 'package:stroke_wars/features/profile/domain/repositories/achievement_repository.dart';

part 'achievement_service.g.dart';

/// Application service managing the active player's achievements and progress.
@riverpod
class AchievementService extends _$AchievementService {
  @override
  void build() {}

  /// Computes the list of achievement progress trackers for the active player.
  List<AchievementProgress> getPlayerAchievementProgress() {
    final player = ref.watch(playerServiceProvider);
    final repo = ref.watch(achievementRepositoryProvider);
    final definitions = repo.getDefinitions();

    if (player == null) return const [];

    final unlocked = player.achievementsUnlocked.toSet();
    final stats = player.statistics;

    return definitions.map((def) {
      final isUnlocked = unlocked.contains(def.id);
      final unlockedAt = isUnlocked ? player.lastPlayed : null;

      // Determine progress values based on stats
      int currentProgress = 0;
      int targetProgress = 1;

      switch (def.id) {
        case 'first_win':
          currentProgress = stats.wins >= 1 ? 1 : 0;
          targetProgress = 1;
        case 'artist_master':
          currentProgress = stats.wordsDrawn;
          targetProgress = 50;
        case 'guess_master':
          currentProgress = stats.wordsGuessed;
          targetProgress = 50;
        case 'perfect_canvas':
          currentProgress = stats.wins >= 1 ? 1 : 0; // Simulated logic
          targetProgress = 1;
        case 'speed_painter':
          currentProgress =
              (stats.fastestGuess != null && stats.fastestGuess! < 3.0) ? 1 : 0;
          targetProgress = 1;
        case 'win_streak_5':
          currentProgress = stats.highestWinStreak;
          targetProgress = 5;
      }

      return AchievementProgress(
        achievementId: def.id,
        isUnlocked: isUnlocked || (currentProgress >= targetProgress),
        unlockedAt: unlockedAt,
        currentProgress: currentProgress.clamp(0, targetProgress),
        targetProgress: targetProgress,
      );
    }).toList();
  }
}
