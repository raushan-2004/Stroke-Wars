import 'package:stroke_wars/features/replay/data/repositories/match_history_repository.dart';
import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';

/// Calculates rich statistical aggregates from historical match logs.
class StatisticsService {
  StatisticsService({MatchHistoryRepository? historyRepository})
    : _historyRepo = historyRepository ?? MatchHistoryRepository();

  final MatchHistoryRepository _historyRepo;

  /// Compiles local records to build the [CloudStatistics] profile.
  Future<CloudStatistics> compileStatistics(String playerId) async {
    final history = await _historyRepo.getMatchHistory();

    int games = 0;
    int wins = 0;
    int losses = 0;
    int highestStreak = 0;
    int currentStreak = 0;

    // Default mock aggregates since brush/colors are drawing layer specific
    final favoriteColors = <String, int>{'#FF0000': 10, '#0000FF': 5};
    const mostUsedBrush = 'classic';

    for (final record in history) {
      games++;
      if (record.winner == playerId || record.winner == 'Host') {
        wins++;
        currentStreak++;
        if (currentStreak > highestStreak) {
          highestStreak = currentStreak;
        }
      } else {
        losses++;
        currentStreak = 0;
      }
    }

    return CloudStatistics(
      games: games,
      wins: wins,
      losses: losses,
      guessAccuracy: games > 0 ? wins / games : 0.0,
      averageDrawTime: games > 0 ? 30.0 : 0.0, // Mock average time calculations
      averageGuessTime: games > 0 ? 12.5 : 0.0,
      highestStreak: highestStreak,
      mostUsedBrush: mostUsedBrush,
      favoriteColors: favoriteColors,
    );
  }
}
