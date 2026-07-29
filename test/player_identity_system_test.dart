import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';
import 'package:stroke_wars/features/profile/application/player_identity_service.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/application/player_statistics_service.dart';
import 'package:stroke_wars/features/profile/domain/models/player_statistics.dart';

class FakeStorageService implements StorageService {
  final Map<String, dynamic> _data = {};

  @override
  T? get<T>(String key) => _data[key] as T?;

  @override
  Future<void> put<T>(String key, T value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

void main() {
  group('Player Identity System (PIS) - Unit Tests', () {
    late ProviderContainer container;
    late FakeStorageService fakeStorage;

    setUp(() {
      fakeStorage = FakeStorageService();
      container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(fakeStorage)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('PlayerIdentityService generates and persists V4 UUID', () {
      final identityService = container.read(
        playerIdentityServiceProvider.notifier,
      );

      // Verify no UUID exists initially
      expect(fakeStorage.containsKey('device_unique_identity_uuid'), isFalse);

      // Generate UUID
      final uuid1 = identityService.getOrCreateUuid();
      expect(uuid1.length, equals(36)); // standard UUID-V4 length
      expect(fakeStorage.containsKey('device_unique_identity_uuid'), isTrue);

      // Re-fetch UUID and verify persistence (never regenerated)
      final uuid2 = identityService.getOrCreateUuid();
      expect(uuid1, equals(uuid2));
    });

    test('PlayerStatisticsService computes statistics accurately', () {
      final statsService = container.read(
        playerStatisticsServiceProvider.notifier,
      );

      // Test win rate
      final stats1 = PlayerStatistics.initial().copyWith(
        gamesPlayed: 10,
        wins: 6,
        losses: 4,
      );
      expect(statsService.calculateWinRate(stats1), equals(60.0));

      final statsZero = PlayerStatistics.initial();
      expect(statsService.calculateWinRate(statsZero), equals(0.0));

      // Test average guess time
      final statsGuess = PlayerStatistics.initial().copyWith(
        wordsGuessed: 4,
        totalGuessTime: 24.0,
      );
      expect(statsService.calculateAverageGuessTime(statsGuess), equals(6.0));
      expect(statsService.calculateAverageGuessTime(statsZero), isNull);

      // Test XP level-up progress
      final statsXp = PlayerStatistics.initial().copyWith(level: 1, xp: 450);
      expect(
        statsService.calculateXpProgress(statsXp),
        equals(0.45),
      ); // 450 / 1000
    });

    test(
      'PlayerService supports profile creation, update, and deletion',
      () async {
        final playerService = container.read(playerServiceProvider.notifier);

        // Verify no player exists initially
        expect(playerService.hasPlayer(), isFalse);
        expect(container.read(playerServiceProvider), isNull);

        // Create Player profile
        await playerService.createPlayer(
          displayName: 'Hero Painter',
          avatarId: 'wizard',
          themeMode: 'dark',
          accentColor: 'cyan',
        );

        expect(playerService.hasPlayer(), isTrue);
        final player = container.read(playerServiceProvider);
        expect(player, isNotNull);
        expect(player!.displayName, equals('Hero Painter'));
        expect(player.cosmetics.avatarId, equals('wizard'));
        expect(player.settings.themeMode, equals('dark'));
        expect(player.settings.accentColor, equals('cyan'));

        // Update Player profile
        final updatedPlayer = player.copyWith(displayName: 'Brush Master');
        await playerService.updatePlayer(updatedPlayer);

        final reFetched = container.read(playerServiceProvider);
        expect(reFetched!.displayName, equals('Brush Master'));

        // Delete Player Profile
        await playerService.clearPlayer();
        expect(playerService.hasPlayer(), isFalse);
        expect(container.read(playerServiceProvider), isNull);
      },
    );

    test(
      'PlayerService processes XP gain and level-up logic correctly',
      () async {
        final playerService = container.read(playerServiceProvider.notifier);

        await playerService.createPlayer(
          displayName: 'Level Tester',
          avatarId: 'robot',
          themeMode: 'system',
          accentColor: 'purple',
        );

        final initialPlayer = container.read(playerServiceProvider)!;
        expect(initialPlayer.statistics.level, equals(1));
        expect(initialPlayer.statistics.xp, equals(0));

        // Record match with XP gain of 1200
        // 1000 XP threshold for Level 1, 200 XP remaining in Level 2
        await playerService.recordMatch(
          won: true,
          guessTime: 4.5,
          xpEarned: 1200,
        );

        final leveledPlayer = container.read(playerServiceProvider)!;
        expect(leveledPlayer.statistics.level, equals(2));
        expect(leveledPlayer.statistics.xp, equals(200));
        expect(leveledPlayer.statistics.wins, equals(1));
        expect(leveledPlayer.statistics.gamesPlayed, equals(1));
        expect(leveledPlayer.statistics.fastestGuess, equals(4.5));
      },
    );
  });
}
