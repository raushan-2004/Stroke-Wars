import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';

/// Centralized evaluator for tracking challenge values, resets, and rewards.
class MissionEngine {
  /// Evaluates progress against active missions for draw, guess, or win actions.
  List<DailyMission> processProgress({
    required List<DailyMission> activeMissions,
    required String
    actionType, // 'draw', 'guess', 'win', 'friend', 'lan', 'online'
    int increment = 1,
  }) {
    return activeMissions.map((mission) {
      if (mission.isCompleted) return mission;

      bool matches = false;
      if (actionType == 'draw' &&
          mission.title.toLowerCase().contains('draw')) {
        matches = true;
      } else if (actionType == 'guess' &&
          mission.title.toLowerCase().contains('guess')) {
        matches = true;
      } else if (actionType == 'win' &&
          mission.title.toLowerCase().contains('win')) {
        matches = true;
      } else if (actionType == 'friend' &&
          mission.title.toLowerCase().contains('friend')) {
        matches = true;
      } else if (actionType == 'lan' &&
          mission.title.toLowerCase().contains('lan')) {
        matches = true;
      } else if (actionType == 'online' &&
          mission.title.toLowerCase().contains('online')) {
        matches = true;
      }

      if (matches) {
        final newVal = mission.currentValue + increment;
        final isComp = newVal >= mission.targetValue;
        return mission.copyWith(
          currentValue: newVal > mission.targetValue
              ? mission.targetValue
              : newVal,
          isCompleted: isComp,
        );
      }
      return mission;
    }).toList();
  }

  /// Refreshes mission lists to a new set of challenges.
  List<DailyMission> generateDailyMissions() {
    return const [
      DailyMission(
        id: 'daily_draw',
        title: 'Draw 3 words',
        targetValue: 3,
        currentValue: 0,
        rewardXp: 200,
        rewardCurrency: 50,
        isCompleted: false,
        isClaimed: false,
      ),
      DailyMission(
        id: 'daily_guess',
        title: 'Guess 5 words',
        targetValue: 5,
        currentValue: 0,
        rewardXp: 300,
        rewardCurrency: 75,
        isCompleted: false,
        isClaimed: false,
      ),
      DailyMission(
        id: 'daily_win',
        title: 'Win 2 matches',
        targetValue: 2,
        currentValue: 0,
        rewardXp: 500,
        rewardCurrency: 100,
        isCompleted: false,
        isClaimed: false,
      ),
    ];
  }

  List<DailyMission> generateWeeklyMissions() {
    return const [
      DailyMission(
        id: 'weekly_friends',
        title: 'Play 5 games with friends',
        targetValue: 5,
        currentValue: 0,
        rewardXp: 1000,
        rewardCurrency: 250,
        isCompleted: false,
        isClaimed: false,
      ),
      DailyMission(
        id: 'weekly_lan',
        title: 'Complete 10 LAN matches',
        targetValue: 10,
        currentValue: 0,
        rewardXp: 1500,
        rewardCurrency: 400,
        isCompleted: false,
        isClaimed: false,
      ),
    ];
  }
}
