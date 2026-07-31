import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';
import 'package:stroke_wars/features/live_services/domain/repositories/cloud_storage.dart';
import 'package:stroke_wars/features/live_services/data/repositories/mock_cloud_storage.dart';
import 'package:stroke_wars/features/live_services/application/player_cloud_service.dart';
import 'package:stroke_wars/features/live_services/application/statistics_service.dart';
import 'package:stroke_wars/features/live_services/application/match_history_service.dart';
import 'package:stroke_wars/features/live_services/application/offline_cache_manager.dart';
import 'package:stroke_wars/features/live_services/application/sync_manager.dart';

part 'live_services_providers.g.dart';

@riverpod
MockCloudStorage mockCloudStorage(MockCloudStorageRef ref) {
  return MockCloudStorage();
}

@riverpod
CloudStorage cloudStorage(CloudStorageRef ref) {
  return ref.watch(mockCloudStorageProvider);
}

@riverpod
PlayerCloudService playerCloudService(PlayerCloudServiceRef ref) {
  final storage = ref.watch(cloudStorageProvider);
  return PlayerCloudService(cloudStorage: storage);
}

@riverpod
StatisticsService statisticsService(StatisticsServiceRef ref) {
  return StatisticsService();
}

@riverpod
MatchHistoryService matchHistoryService(MatchHistoryServiceRef ref) {
  final storage = ref.watch(cloudStorageProvider);
  return MatchHistoryService(storage: storage);
}

@riverpod
OfflineCacheManager offlineCacheManager(OfflineCacheManagerRef ref) {
  return OfflineCacheManager();
}

@riverpod
SyncManager syncManager(SyncManagerRef ref) {
  return SyncManager(
    playerCloudService: ref.watch(playerCloudServiceProvider),
    statisticsService: ref.watch(statisticsServiceProvider),
    matchHistoryService: ref.watch(matchHistoryServiceProvider),
    offlineCacheManager: ref.watch(offlineCacheManagerProvider),
  );
}

@riverpod
class SyncStatusState extends _$SyncStatusState {
  SyncManager? _manager;

  @override
  SyncStatus build() {
    _manager = ref.watch(syncManagerProvider);
    _manager!.addListener(_update);
    ref.onDispose(() {
      _manager?.removeListener(_update);
    });
    return _manager!.status;
  }

  void _update(SyncStatus status) {
    state = status;
  }
}
