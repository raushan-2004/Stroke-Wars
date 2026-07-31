import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';
import 'package:stroke_wars/features/live_services/data/repositories/mock_cloud_storage.dart';
import 'package:stroke_wars/features/live_services/application/player_cloud_service.dart';
import 'package:stroke_wars/features/live_services/application/statistics_service.dart';
import 'package:stroke_wars/features/live_services/application/match_history_service.dart';
import 'package:stroke_wars/features/live_services/application/offline_cache_manager.dart';
import 'package:stroke_wars/features/live_services/application/sync_manager.dart';
import 'package:flutter/services.dart';
import 'package:stroke_wars/features/profile/domain/models/match_history.dart';

void main() {
  group('Backend & Live Services (Stage 10) — Integration Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async {
              return '.';
            },
          );
    });
    late MockCloudStorage storage;
    late PlayerCloudService playerCloudService;
    late StatisticsService statisticsService;
    late MatchHistoryService matchHistoryService;
    late OfflineCacheManager offlineCacheManager;
    late SyncManager syncManager;

    setUp(() {
      storage = MockCloudStorage();
      playerCloudService = PlayerCloudService(cloudStorage: storage);
      statisticsService = StatisticsService();
      matchHistoryService = MatchHistoryService(storage: storage);
      offlineCacheManager = OfflineCacheManager(maxQueueSize: 5);
      syncManager = SyncManager(
        playerCloudService: playerCloudService,
        statisticsService: statisticsService,
        matchHistoryService: matchHistoryService,
        offlineCacheManager: offlineCacheManager,
      );
    });

    test('CloudCapabilities match backend requirements', () {
      final caps = storage.capabilities;
      expect(caps.profileSync, isTrue);
      expect(caps.replaySync, isTrue);
      expect(caps.maximumReplaySize, equals(2 * 1024 * 1024));
    });

    test('PlayerCloudService uploads and downloads profiles', () async {
      const profile = CloudProfile(
        playerId: 'user-1',
        displayName: 'Alice',
        avatar: 'avatar_red',
        statistics: CloudStatistics(
          games: 10,
          wins: 5,
          losses: 5,
          guessAccuracy: 0.5,
          averageDrawTime: 25.0,
          averageGuessTime: 10.0,
          highestStreak: 3,
          mostUsedBrush: 'classic',
          favoriteColors: {},
        ),
        achievements: ['first_win'],
        xp: 1500,
        level: 5,
        cosmetics: ['classic_brush'],
        cloudSaveVersion: 2,
      );

      await playerCloudService.uploadProfile(profile);

      final downloaded = await playerCloudService.downloadProfile('user-1');
      expect(downloaded, isNotNull);
      expect(downloaded!.displayName, equals('Alice'));
      expect(downloaded.cloudSaveVersion, equals(2));
    });

    test('Conflict Resolution merges statistics and chooses best values', () {
      const local = CloudProfile(
        playerId: 'user-1',
        displayName: 'Alice Local',
        avatar: 'avatar_red',
        statistics: CloudStatistics(
          games: 5,
          wins: 3,
          losses: 2,
          guessAccuracy: 0.6,
          averageDrawTime: 20.0,
          averageGuessTime: 8.0,
          highestStreak: 2,
          mostUsedBrush: 'classic',
          favoriteColors: {'#FF0000': 5},
        ),
        achievements: ['win_1'],
        xp: 1000,
        level: 3,
        cosmetics: [],
        cloudSaveVersion: 1,
      );

      const cloud = CloudProfile(
        playerId: 'user-1',
        displayName: 'Alice Cloud',
        avatar: 'avatar_red',
        statistics: CloudStatistics(
          games: 10,
          wins: 6,
          losses: 4,
          guessAccuracy: 0.6,
          averageDrawTime: 24.0,
          averageGuessTime: 12.0,
          highestStreak: 4,
          mostUsedBrush: 'neon',
          favoriteColors: {'#0000FF': 3},
        ),
        achievements: ['win_5'],
        xp: 2500,
        level: 5,
        cosmetics: ['neon_brush'],
        cloudSaveVersion: 3,
      );

      // Strategy: Local wins
      final localWins = playerCloudService.resolveConflict(
        local: local,
        cloud: cloud,
        strategy: SyncConflictStrategy.localWins,
      );
      expect(localWins.displayName, equals('Alice Local'));

      // Strategy: Cloud wins
      final cloudWins = playerCloudService.resolveConflict(
        local: local,
        cloud: cloud,
        strategy: SyncConflictStrategy.cloudWins,
      );
      expect(cloudWins.displayName, equals('Alice Cloud'));

      // Strategy: Merge
      final merged = playerCloudService.resolveConflict(
        local: local,
        cloud: cloud,
        strategy: SyncConflictStrategy.merge,
      );
      expect(merged.level, equals(5)); // Cloud level (5) > Local level (3)
      expect(merged.xp, equals(2500)); // Cloud XP (2500) > Local XP (1000)
      expect(merged.achievements, containsAll(['win_1', 'win_5']));
      expect(merged.statistics.games, equals(15));
      expect(merged.statistics.wins, equals(9));
      expect(merged.statistics.losses, equals(6));
      expect(merged.statistics.highestStreak, equals(4)); // Max of 2 and 4
      expect(
        merged.statistics.favoriteColors.keys,
        containsAll(['#FF0000', '#0000FF']),
      );
      expect(merged.cloudSaveVersion, equals(4)); // max(1, 3) + 1
    });

    test(
      'OfflineCacheManager handles FIFO queue, deduplication, and max limits',
      () async {
        await offlineCacheManager.clearQueue();

        final t1 = OfflineTask(
          id: 't-1',
          type: OfflineTaskType.uploadProfile,
          payload: const {'version': 1},
          createdAt: DateTime.now(),
        );
        final t2 = OfflineTask(
          id: 't-2',
          type: OfflineTaskType.uploadProfile,
          payload: const {'version': 2},
          createdAt: DateTime.now(),
        );

        // Enqueue profile upload twice: t2 must deduplicate and replace t1!
        await offlineCacheManager.enqueueTask(t1);
        await offlineCacheManager.enqueueTask(t2);

        var tasks = await offlineCacheManager.loadTasks();
        expect(tasks, hasLength(1));
        expect(tasks.first.id, equals('t-2'));

        // Fill queue to test max limit (maxQueueSize is 5)
        for (int i = 3; i <= 8; i++) {
          await offlineCacheManager.enqueueTask(
            OfflineTask(
              id: 't-$i',
              type: OfflineTaskType.uploadMatchSummary,
              payload: const {},
              createdAt: DateTime.now(),
            ),
          );
        }

        tasks = await offlineCacheManager.loadTasks();
        expect(tasks.length, lessThanOrEqualTo(5));
        // Oldest task t-2 must have been discarded to accommodate new limits (FIFO)
        expect(tasks.any((t) => t.id == 't-2'), isFalse);
      },
    );

    test('SyncManager schedules and drains task queue when online', () async {
      await offlineCacheManager.clearQueue();

      final localProfile = CloudProfile(
        playerId: 'user-1',
        displayName: 'Bob',
        avatar: 'avatar_blue',
        statistics: const CloudStatistics(
          games: 1,
          wins: 1,
          losses: 0,
          guessAccuracy: 1.0,
          averageDrawTime: 10,
          averageGuessTime: 5,
          highestStreak: 1,
          mostUsedBrush: 'classic',
          favoriteColors: {},
        ),
        achievements: const [],
        xp: 100,
        level: 1,
        cosmetics: const [],
        cloudSaveVersion: 1,
      );

      // 1. Simulating Sync while Offline: should queue task
      await syncManager.setOnline(false);
      await syncManager.synchronize(localProfile);

      expect(syncManager.status, equals(SyncStatus.offline));
      var pending = await offlineCacheManager.loadTasks();
      expect(pending, hasLength(1));
      expect(pending.first.type, equals(OfflineTaskType.uploadProfile));

      // 2. Simulating Restoration: goes online and synchronization completes successfully
      await syncManager.setOnline(true, currentLocalProfile: localProfile);
      expect(syncManager.status, equals(SyncStatus.completed));

      pending = await offlineCacheManager.loadTasks();
      expect(pending, isEmpty); // Queue must have been drained

      final cloudProfile = await playerCloudService.downloadProfile('user-1');
      expect(cloudProfile, isNotNull);
      expect(cloudProfile!.displayName, equals('Bob'));
    });

    test('SyncManager interrupted synchronization / network failures', () async {
      await offlineCacheManager.clearQueue();

      final localProfile = CloudProfile(
        playerId: 'user-1',
        displayName: 'Bob',
        avatar: 'avatar_blue',
        statistics: const CloudStatistics(
          games: 1,
          wins: 1,
          losses: 0,
          guessAccuracy: 1.0,
          averageDrawTime: 10,
          averageGuessTime: 5,
          highestStreak: 1,
          mostUsedBrush: 'classic',
          favoriteColors: {},
        ),
        achievements: const [],
        xp: 100,
        level: 1,
        cosmetics: const [],
        cloudSaveVersion: 1,
      );

      // Simulating interrupted network connection: should result in failure state
      await syncManager.setOnline(true);
      storage.simulateFailure = true;

      await syncManager.synchronize(localProfile);
      expect(syncManager.status, equals(SyncStatus.failed));
    });

    test('Remote Config fetching and malformed responses handling', () async {
      // Successful fetch
      final config = await storage.fetchLiveConfig();
      expect(config.xpMultiplier, equals(1.5));
      expect(config.seasonName, equals('Season 1: Genesis'));

      // Malformed response test
      storage.simulateMalformedResponse = true;
      expect(() => storage.fetchLiveConfig(), throwsA(isA<FormatException>()));
    });
  });
}
