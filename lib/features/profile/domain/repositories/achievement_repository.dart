import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/profile/domain/models/achievement.dart';

part 'achievement_repository.g.dart';

/// Repository responsible for loading achievement definitions.
abstract interface class AchievementRepository {
  /// Loads all standard achievement definitions.
  List<AchievementDefinition> getDefinitions();
}

/// Simple hardcoded implementation of [AchievementRepository].
class LocalAchievementRepository implements AchievementRepository {
  @override
  List<AchievementDefinition> getDefinitions() {
    return const [
      AchievementDefinition(
        id: 'first_win',
        title: 'First Victory',
        description: 'Win your first multiplayer drawing game.',
        points: 100,
      ),
      AchievementDefinition(
        id: 'artist_master',
        title: 'Master Artist',
        description: 'Successfully draw 50 secret words.',
        points: 250,
      ),
      AchievementDefinition(
        id: 'guess_master',
        title: 'Master Guesser',
        description: 'Correctly guess 50 opponent drawings.',
        points: 250,
      ),
      AchievementDefinition(
        id: 'perfect_canvas',
        title: 'Perfect Canvas',
        description: 'Win a game with 100% correct artist drawing ratings.',
        points: 500,
      ),
      AchievementDefinition(
        id: 'speed_painter',
        title: 'Speed Painter',
        description: 'Correctly guess a drawing in under 3 seconds.',
        points: 200,
      ),
      AchievementDefinition(
        id: 'win_streak_5',
        title: 'Unstoppable',
        description: 'Reach a win streak of 5 consecutive games.',
        points: 400,
      ),
    ];
  }
}

/// Riverpod provider for [AchievementRepository].
@riverpod
AchievementRepository achievementRepository(AchievementRepositoryRef ref) {
  return LocalAchievementRepository();
}
