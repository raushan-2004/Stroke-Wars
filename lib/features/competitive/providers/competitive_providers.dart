import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';
import 'package:stroke_wars/features/competitive/application/progression_service.dart';
import 'package:stroke_wars/features/competitive/application/ranked_service.dart';
import 'package:stroke_wars/features/competitive/application/mission_engine.dart';
import 'package:stroke_wars/features/competitive/application/economy_service.dart';
import 'package:stroke_wars/features/competitive/application/social_service.dart';
import 'package:stroke_wars/features/competitive/application/notification_center.dart';

part 'competitive_providers.g.dart';

@riverpod
ProgressionEngine progressionEngine(ProgressionEngineRef ref) =>
    ProgressionEngine();

@riverpod
RankedService rankedService(RankedServiceRef ref) => RankedService();

@riverpod
MissionEngine missionEngine(MissionEngineRef ref) => MissionEngine();

@riverpod
EconomyService economyService(EconomyServiceRef ref) => EconomyService();

@riverpod
SocialGraphService socialGraphService(SocialGraphServiceRef ref) =>
    SocialGraphService();

@riverpod
NotificationCenter notificationCenter(NotificationCenterRef ref) =>
    NotificationCenter();

@riverpod
class ActiveProgression extends _$ActiveProgression {
  @override
  PlayerProgression build() {
    return const PlayerProgression(
      xp: 0,
      level: 1,
      seasonXp: 0,
      rank: 'Bronze I',
      prestige: 0,
      badges: ['rookie_badge'],
      titles: ['Novice'],
      unlockHistory: [],
    );
  }

  void gainXp(int amount) {
    final engine = ref.read(progressionEngineProvider);
    state = engine.addXp(state, amount);
  }

  void reset() {
    state = const PlayerProgression(
      xp: 0,
      level: 1,
      seasonXp: 0,
      rank: 'Bronze I',
      prestige: 0,
      badges: ['rookie_badge'],
      titles: ['Novice'],
      unlockHistory: [],
    );
  }
}

@riverpod
class ActiveSeasonProgress extends _$ActiveSeasonProgress {
  @override
  SeasonProgress build() {
    return const SeasonProgress(
      seasonId: 'season_genesis',
      seasonXp: 0,
      currentTier: 1,
      rewardsClaimed: [],
      challengesCompleted: [],
    );
  }

  void advanceSeasonXp(int xp) {
    final newXp = state.seasonXp + xp;
    final newTier = (newXp ~/ 500) + 1; // 500 XP per season tier
    state = state.copyWith(seasonXp: newXp, currentTier: newTier);
  }

  void claimReward(String rewardId) {
    final claimed = List<String>.from(state.rewardsClaimed);
    if (!claimed.contains(rewardId)) {
      claimed.add(rewardId);
      state = state.copyWith(rewardsClaimed: claimed);
    }
  }

  void resetSeason() {
    state = const SeasonProgress(
      seasonId: 'season_genesis',
      seasonXp: 0,
      currentTier: 1,
      rewardsClaimed: [],
      challengesCompleted: [],
    );
  }
}

@riverpod
class ActiveDailyMissions extends _$ActiveDailyMissions {
  @override
  List<DailyMission> build() {
    return ref.watch(missionEngineProvider).generateDailyMissions();
  }

  void addProgress(String type) {
    final engine = ref.read(missionEngineProvider);
    state = engine.processProgress(activeMissions: state, actionType: type);
  }

  void claimMissionReward(String missionId) {
    state = state.map((m) {
      if (m.id == missionId && m.isCompleted && !m.isClaimed) {
        // Award XP and Currency
        ref.read(activeProgressionProvider.notifier).gainXp(m.rewardXp);
        ref.read(economyServiceProvider).addCoins(m.rewardCurrency);

        // Notify
        ref
            .read(notificationCenterProvider)
            .postNotification(
              title: 'Mission Reward Claimed!',
              body:
                  'Received ${m.rewardXp} XP and ${m.rewardCurrency} Coins for completing: "${m.title}"',
              type: 'mission_reward',
            );

        return m.copyWith(isClaimed: true);
      }
      return m;
    }).toList();
  }

  void forceResets() {
    state = ref.read(missionEngineProvider).generateDailyMissions();
  }
}

@riverpod
class ActiveNotifications extends _$ActiveNotifications {
  NotificationCenter? _center;

  @override
  List<SWNotification> build() {
    _center = ref.watch(notificationCenterProvider);
    _center!.addListener(_update);
    ref.onDispose(() {
      _center?.removeListener(_update);
    });
    return _center!.notifications;
  }

  void _update(List<SWNotification> list) {
    state = list;
  }

  void dismiss(String id) {
    _center?.dismissNotification(id);
  }

  void clearAll() {
    _center?.clearAll();
  }
}
