import 'dart:async';
import 'package:stroke_wars/features/profile/domain/models/match_history.dart';
import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';
import 'package:stroke_wars/features/live_services/application/player_cloud_service.dart';
import 'package:stroke_wars/features/live_services/application/statistics_service.dart';
import 'package:stroke_wars/features/live_services/application/match_history_service.dart';
import 'package:stroke_wars/features/live_services/application/offline_cache_manager.dart';

/// Orchestrator scheduling uploads, conflict resolutions, and connectivity retries.
class SyncManager {
  SyncManager({
    required PlayerCloudService playerCloudService,
    required StatisticsService statisticsService,
    required MatchHistoryService matchHistoryService,
    required OfflineCacheManager offlineCacheManager,
  }) : _playerCloudService = playerCloudService,
       _statisticsService = statisticsService,
       _matchHistoryService = matchHistoryService,
       _offlineCacheManager = offlineCacheManager;

  final PlayerCloudService _playerCloudService;
  final StatisticsService _statisticsService;
  final MatchHistoryService _matchHistoryService;
  final OfflineCacheManager _offlineCacheManager;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final List<void Function(SyncStatus)> _listeners = [];

  void addListener(void Function(SyncStatus) listener) {
    _listeners.add(listener);
    listener(_status);
  }

  void removeListener(void Function(SyncStatus) listener) {
    _listeners.remove(listener);
  }

  /// Sets connectivity status and triggers draining of queue if back online.
  Future<void> setOnline(
    bool online, {
    CloudProfile? currentLocalProfile,
  }) async {
    _isOnline = online;
    if (online) {
      _updateStatus(SyncStatus.idle);
      if (currentLocalProfile != null) {
        await synchronize(currentLocalProfile);
      } else {
        await drainOfflineQueue();
      }
    } else {
      _updateStatus(SyncStatus.offline);
    }
  }

  /// Orchestrates full profile, stats, and queue synchronization.
  Future<void> synchronize(
    CloudProfile localProfile, {
    SyncConflictStrategy conflictStrategy = SyncConflictStrategy.merge,
  }) async {
    if (!_isOnline) {
      _updateStatus(SyncStatus.offline);
      // Queue local profile update
      await _offlineCacheManager.enqueueTask(
        OfflineTask(
          id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
          type: OfflineTaskType.uploadProfile,
          payload: localProfile.toJson(),
          createdAt: DateTime.now(),
        ),
      );
      return;
    }

    _updateStatus(SyncStatus.syncing);

    try {
      // 1. Download Cloud Profile
      final cloudProfile = await _playerCloudService.downloadProfile(
        localProfile.playerId,
      );

      CloudProfile finalProfile = localProfile;

      if (cloudProfile != null) {
        if (cloudProfile.cloudSaveVersion > localProfile.cloudSaveVersion) {
          // Sync Conflict! Resolve using strategy
          _updateStatus(SyncStatus.conflict);
          finalProfile = _playerCloudService.resolveConflict(
            local: localProfile,
            cloud: cloudProfile,
            strategy: conflictStrategy,
          );
          _updateStatus(SyncStatus.syncing);
        }
      }

      // 2. Upload latest Profile
      await _playerCloudService.uploadProfile(finalProfile);

      // 3. Compile and upload latest statistics
      final stats = await _statisticsService.compileStatistics(
        localProfile.playerId,
      );
      final finalProfileWithStats = CloudProfile(
        playerId: finalProfile.playerId,
        displayName: finalProfile.displayName,
        avatar: finalProfile.avatar,
        statistics: stats,
        achievements: finalProfile.achievements,
        xp: finalProfile.xp,
        level: finalProfile.level,
        cosmetics: finalProfile.cosmetics,
        cloudSaveVersion: finalProfile.cloudSaveVersion,
      );
      await _playerCloudService.uploadProfile(finalProfileWithStats);

      // 4. Batch drain other tasks
      await drainOfflineQueue();

      _updateStatus(SyncStatus.completed);
    } catch (_) {
      _updateStatus(SyncStatus.failed);
    }
  }

  /// Iterates and retries queued offline tasks.
  Future<void> drainOfflineQueue() async {
    if (!_isOnline) return;

    final tasks = await _offlineCacheManager.loadTasks();
    if (tasks.isEmpty) return;

    for (final task in tasks) {
      try {
        if (task.type == OfflineTaskType.uploadProfile) {
          final profile = CloudProfile.fromJson(task.payload);
          await _playerCloudService.uploadProfile(profile);
        } else if (task.type == OfflineTaskType.uploadMatchSummary) {
          final history = MatchHistory.fromJson(task.payload);
          await _matchHistoryService.uploadMatchSummary(
            task.id.replaceAll('match_', ''),
            history,
          );
        }
        // Dequeue task upon successful sync
        await _offlineCacheManager.dequeueTask(task.id);
      } catch (_) {
        await _offlineCacheManager.incrementRetry(task.id);
        _updateStatus(SyncStatus.retrying);
        break; // Pause draining on failure
      }
    }
  }

  /// Formats and schedules a new MatchHistory upload task.
  Future<void> scheduleMatchUpload(String userId, MatchHistory history) async {
    final task = OfflineTask(
      id: 'match_${history.matchId}',
      type: OfflineTaskType.uploadMatchSummary,
      payload: history.toJson(),
      createdAt: DateTime.now(),
    );

    if (!_isOnline) {
      await _offlineCacheManager.enqueueTask(task);
      return;
    }

    try {
      await _matchHistoryService.uploadMatchSummary(userId, history);
    } catch (_) {
      await _offlineCacheManager.enqueueTask(task);
    }
  }

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    for (final listener in _listeners) {
      listener(newStatus);
    }
  }
}
