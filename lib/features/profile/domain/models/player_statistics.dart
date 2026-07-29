import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_statistics.freezed.dart';
part 'player_statistics.g.dart';

/// Player game statistics tracked locally.
@freezed
class PlayerStatistics with _$PlayerStatistics {
  /// Creates a [PlayerStatistics].
  const factory PlayerStatistics({
    required int gamesPlayed,
    required int wins,
    required int losses,
    required int currentWinStreak,
    required int highestWinStreak,
    required int wordsDrawn,
    required int wordsGuessed,
    required double? fastestGuess,
    required double? totalGuessTime,
    required int xp,
    required int level,
  }) = _PlayerStatistics;

  /// Creates a [PlayerStatistics] from JSON map.
  factory PlayerStatistics.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatisticsFromJson(json);

  /// Default starting stats for new players.
  factory PlayerStatistics.initial() => const PlayerStatistics(
    gamesPlayed: 0,
    wins: 0,
    losses: 0,
    currentWinStreak: 0,
    highestWinStreak: 0,
    wordsDrawn: 0,
    wordsGuessed: 0,
    fastestGuess: null,
    totalGuessTime: null,
    xp: 0,
    level: 1,
  );
}
