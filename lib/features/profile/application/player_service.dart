import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/features/profile/application/player_identity_service.dart';
import 'package:stroke_wars/features/profile/data/repositories/player_repository_impl.dart';
import 'package:stroke_wars/features/profile/domain/models/player.dart';
import 'package:stroke_wars/features/profile/domain/models/player_cosmetics.dart';
import 'package:stroke_wars/features/profile/domain/models/player_settings.dart';
import 'package:stroke_wars/features/profile/domain/models/player_statistics.dart';

part 'player_service.g.dart';

/// Notifier driving the active player state and profile coordination.
@riverpod
class PlayerService extends _$PlayerService {
  @override
  Player? build() {
    final repo = ref.watch(playerRepositoryProvider);
    return repo.getPlayer();
  }

  /// Returns whether a player profile exists locally.
  bool hasPlayer() => state != null;

  /// Creates a new player profile and persists it.
  Future<void> createPlayer({
    required String displayName,
    required String avatarId,
    required String themeMode,
    required String accentColor,
    String? profilePicturePath,
  }) async {
    final uuid = ref
        .read(playerIdentityServiceProvider.notifier)
        .getOrCreateUuid();

    final newPlayer = Player(
      uuid: uuid,
      displayName: displayName,
      username: null,
      profilePicturePath: profilePicturePath,
      settings: PlayerSettings.initial().copyWith(
        themeMode: themeMode,
        accentColor: accentColor,
      ),
      cosmetics: PlayerCosmetics.initial().copyWith(
        avatarId: avatarId,
        theme: themeMode,
        accentColor: accentColor,
      ),
      statistics: PlayerStatistics.initial(),
      achievementsUnlocked: const [],
      createdAt: DateTime.now(),
      lastPlayed: DateTime.now(),
      appVersion: '1.0.0',
    );

    final repo = ref.read(playerRepositoryProvider);
    await repo.savePlayer(newPlayer);
    state = newPlayer;
  }

  /// Updates active player aggregate properties.
  Future<void> updatePlayer(Player player) async {
    final repo = ref.read(playerRepositoryProvider);
    await repo.savePlayer(player);
    state = player;
  }

  /// Reset/clear all player properties.
  Future<void> clearPlayer() async {
    final repo = ref.read(playerRepositoryProvider);
    await repo.clearPlayer();
    state = null;
  }

  /// Records a completed game match statistics and processes XP.
  Future<void> recordMatch({
    required bool won,
    required double? guessTime,
    required int xpEarned,
  }) async {
    final current = state;
    if (current == null) return;

    final stats = current.statistics;
    final newGamesPlayed = stats.gamesPlayed + 1;
    final newWins = stats.wins + (won ? 1 : 0);
    final newLosses = stats.losses + (won ? 0 : 1);
    final newStreak = won ? (stats.currentWinStreak + 1) : 0;
    final newHighestStreak = newStreak > stats.highestWinStreak
        ? newStreak
        : stats.highestWinStreak;

    // Check fastest guess
    double? newFastest = stats.fastestGuess;
    if (won && guessTime != null) {
      newFastest = newFastest == null || guessTime < newFastest
          ? guessTime
          : newFastest;
    }

    // Add guess statistics
    final newWordsGuessed = stats.wordsGuessed + (guessTime != null ? 1 : 0);
    final newTotalGuessTime =
        (stats.totalGuessTime ?? 0.0) + (guessTime ?? 0.0);

    // Level-up math
    int xp = stats.xp + xpEarned;
    int level = stats.level;
    int threshold = level * 1000;
    while (xp >= threshold) {
      xp -= threshold;
      level++;
      threshold = level * 1000;
    }

    final updatedStats = stats.copyWith(
      gamesPlayed: newGamesPlayed,
      wins: newWins,
      losses: newLosses,
      currentWinStreak: newStreak,
      highestWinStreak: newHighestStreak,
      fastestGuess: newFastest,
      totalGuessTime: newTotalGuessTime > 0.0 ? newTotalGuessTime : null,
      wordsGuessed: newWordsGuessed,
      xp: xp,
      level: level,
    );

    final updatedPlayer = current.copyWith(
      statistics: updatedStats,
      lastPlayed: DateTime.now(),
    );

    await updatePlayer(updatedPlayer);
  }
}

/// Riverpod provider for player settings dynamically synced from active player state.
@riverpod
PlayerSettings playerSettings(PlayerSettingsRef ref) {
  final player = ref.watch(playerServiceProvider);
  if (player != null) {
    return player.settings;
  }
  // Fallback to storage key for initial setup flow
  final storage = ref.watch(storageServiceProvider);
  final stored = storage.get<String>('theme_mode') ?? 'system';
  return PlayerSettings.initial().copyWith(themeMode: stored);
}
