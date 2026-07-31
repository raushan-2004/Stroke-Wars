import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';
import 'package:stroke_wars/features/live_services/domain/repositories/cloud_storage.dart';

/// Service responsible purely for profile storage tasks and conflict resolution.
class PlayerCloudService {
  PlayerCloudService({required CloudStorage cloudStorage})
    : _storage = cloudStorage;

  final CloudStorage _storage;

  /// Uploads a profile directly without queuing or retries.
  Future<void> uploadProfile(CloudProfile profile) async {
    await _storage.uploadProfile(profile.playerId, profile.toJson());
  }

  /// Downloads a profile directly from the cloud.
  Future<CloudProfile?> downloadProfile(String userId) async {
    final data = await _storage.downloadProfile(userId);
    if (data == null) return null;
    return CloudProfile.fromJson(data);
  }

  /// Merges two profiles according to a specified [SyncConflictStrategy].
  CloudProfile resolveConflict({
    required CloudProfile local,
    required CloudProfile cloud,
    required SyncConflictStrategy strategy,
  }) {
    return switch (strategy) {
      SyncConflictStrategy.localWins => local,
      SyncConflictStrategy.cloudWins => cloud,
      SyncConflictStrategy.merge => _mergeProfiles(local, cloud),
      SyncConflictStrategy.manualResolution =>
        local, // Falls back to local in mock manual mode
    };
  }

  CloudProfile _mergeProfiles(CloudProfile local, CloudProfile cloud) {
    // 1. Take higher level and higher XP
    final maxLevel = local.level > cloud.level ? local.level : cloud.level;
    final maxXP = local.xp > cloud.xp ? local.xp : cloud.xp;

    // 2. Union achievements and cosmetics list
    final achievementsUnion = <String>{
      ...local.achievements,
      ...cloud.achievements,
    }.toList();

    final cosmeticsUnion = <String>{
      ...local.cosmetics,
      ...cloud.cosmetics,
    }.toList();

    // 3. Combine statistics fields taking best values
    final statsLocal = local.statistics;
    final statsCloud = cloud.statistics;

    final mergedStats = CloudStatistics(
      games: statsLocal.games + statsCloud.games,
      wins: statsLocal.wins + statsCloud.wins,
      losses: statsLocal.losses + statsCloud.losses,
      guessAccuracy: statsLocal.guessAccuracy > statsCloud.guessAccuracy
          ? statsLocal.guessAccuracy
          : statsCloud.guessAccuracy,
      averageDrawTime: statsLocal.averageDrawTime > 0
          ? (statsLocal.averageDrawTime + statsCloud.averageDrawTime) / 2
          : statsCloud.averageDrawTime,
      averageGuessTime: statsLocal.averageGuessTime > 0
          ? (statsLocal.averageGuessTime + statsCloud.averageGuessTime) / 2
          : statsCloud.averageGuessTime,
      highestStreak: statsLocal.highestStreak > statsCloud.highestStreak
          ? statsLocal.highestStreak
          : statsCloud.highestStreak,
      mostUsedBrush: statsLocal.mostUsedBrush,
      favoriteColors: _mergeColorMaps(
        statsLocal.favoriteColors,
        statsCloud.favoriteColors,
      ),
    );

    return CloudProfile(
      playerId: local.playerId,
      displayName: local.displayName,
      avatar: local.avatar,
      statistics: mergedStats,
      achievements: achievementsUnion,
      xp: maxXP,
      level: maxLevel,
      cosmetics: cosmeticsUnion,
      // Increment save version on merge
      cloudSaveVersion:
          (local.cloudSaveVersion > cloud.cloudSaveVersion
              ? local.cloudSaveVersion
              : cloud.cloudSaveVersion) +
          1,
    );
  }

  Map<String, int> _mergeColorMaps(Map<String, int> a, Map<String, int> b) {
    final result = Map<String, int>.from(a);
    b.forEach((key, value) {
      result[key] = (result[key] ?? 0) + value;
    });
    return result;
  }
}
