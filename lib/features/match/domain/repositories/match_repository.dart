import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';

/// Abstract repository interface for [Match] persistence.
///
/// Implementations are provided by the infrastructure layer.
/// The domain never depends on concrete storage mechanisms.
abstract interface class MatchRepository {
  /// Persists or updates a [Match].
  Future<void> saveMatch(Match match);

  /// Retrieves a [Match] by its [MatchId], or null if not found.
  Future<Match?> getMatch(MatchId id);

  /// Returns all matches the given [playerId] participated in.
  Future<List<Match>> getMatchHistory(String playerId);

  /// Permanently deletes the match with the given [id].
  Future<void> deleteMatch(MatchId id);

  /// Emits the current [Match] and every subsequent update.
  Stream<Match> watchMatch(MatchId id);
}
