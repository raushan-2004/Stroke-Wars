import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';

/// Centralized engine computing XP curves, level upgrades, prestiges, and title/badge unlocks.
class ProgressionEngine {
  /// Amount of XP required to level up. Grows linearly.
  int xpForNextLevel(int currentLevel) {
    return currentLevel * 1000;
  }

  /// Evaluates XP gain and processes potential level-ups, prestige milestones, and badge awards.
  PlayerProgression addXp(
    PlayerProgression current,
    int amount, {
    double multiplier = 1.0,
  }) {
    final netAmount = (amount * multiplier).toInt();
    int newXp = current.xp + netAmount;
    int newSeasonXp = current.seasonXp + netAmount;
    int newLevel = current.level;
    int newPrestige = current.prestige;

    final newBadges = List<String>.from(current.badges);
    final newTitles = List<String>.from(current.titles);
    final newUnlockHistory = List<String>.from(current.unlockHistory);

    // 1. Process level-up loop
    while (true) {
      final req = xpForNextLevel(newLevel);
      if (newXp >= req) {
        newXp -= req;
        newLevel++;

        // Add unlock milestone log
        newUnlockHistory.add('Reached Level $newLevel');

        // Check for prestige milestone at Level 50
        if (newLevel > 50) {
          newLevel = 1;
          newPrestige++;
          newUnlockHistory.add(
            'Prestige Milestone: Level 50 reached! Prestige Tier: $newPrestige',
          );
          if (!newBadges.contains('prestige_$newPrestige')) {
            newBadges.add('prestige_$newPrestige');
          }
        }

        // Title unlocks at specific levels
        if (newLevel == 10 && !newTitles.contains('Scribbler')) {
          newTitles.add('Scribbler');
          newUnlockHistory.add('Title Unlocked: Scribbler');
        } else if (newLevel == 25 && !newTitles.contains('Doodler')) {
          newTitles.add('Doodler');
          newUnlockHistory.add('Title Unlocked: Doodler');
        } else if (newLevel == 50 && !newTitles.contains('Grandmaster')) {
          newTitles.add('Grandmaster');
          newUnlockHistory.add('Title Unlocked: Grandmaster');
        }
      } else {
        break;
      }
    }

    return current.copyWith(
      xp: newXp,
      level: newLevel,
      seasonXp: newSeasonXp,
      prestige: newPrestige,
      badges: newBadges,
      titles: newTitles,
      unlockHistory: newUnlockHistory,
    );
  }
}
