/// Interface contract for fetching leaderboards across multiple tiers.
abstract interface class LeaderboardService {
  /// Fetches top players globally.
  Future<List<Map<String, dynamic>>> fetchGlobalLeaderboard({int limit = 50});

  /// Fetches leaderboard among a list of friends.
  Future<List<Map<String, dynamic>>> fetchFriendsLeaderboard(
    List<String> friendIds,
  );

  /// Fetches leaderboard for the current week.
  Future<List<Map<String, dynamic>>> fetchWeeklyLeaderboard();

  /// Fetches leaderboard for the current month.
  Future<List<Map<String, dynamic>>> fetchMonthlyLeaderboard();

  /// Fetches leaderboard for the active competitive season.
  Future<List<Map<String, dynamic>>> fetchSeasonalLeaderboard(String seasonId);
}
