import 'package:stroke_wars/features/match/domain/models/match_statistics.dart';

/// Abstract repository interface for match statistics persistence.
abstract interface class StatisticsRepository {
  /// Persists statistics for one player for one match.
  Future<void> saveStatistics(MatchStatistics stats);

  /// Returns the statistics for [playerId] from a specific match, or null.
  Future<MatchStatistics?> getStatistics({
    required String playerId,
    required String matchId,
  });

  /// Returns all recorded statistics for [playerId] across all matches.
  Future<List<MatchStatistics>> getAllStatisticsForPlayer(String playerId);

  /// Returns up to [limit] entries sorted by total points descending.
  Future<List<MatchStatistics>> getLeaderboard({int limit = 10});

  /// Permanently removes statistics for a given [matchId].
  Future<void> deleteMatchStatistics(String matchId);
}
