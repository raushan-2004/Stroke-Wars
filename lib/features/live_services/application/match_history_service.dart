import 'package:stroke_wars/features/profile/domain/models/match_history.dart';
import 'package:stroke_wars/features/live_services/domain/repositories/cloud_storage.dart';

/// Formats and schedules match summary uploads to cloud backends.
class MatchHistoryService {
  MatchHistoryService({required CloudStorage storage}) : _storage = storage;

  final CloudStorage _storage;

  /// Directly uploads a formatted summary map to cloud storage.
  Future<void> uploadMatchSummary(String userId, MatchHistory history) async {
    final Map<String, dynamic> summary = {
      'matchId': history.matchId,
      'timestamp': history.playedAt.toIso8601String(),
      'durationSecs': history.duration,
      'gameMode': history.gameMode,
      'winner': history.winner,
      'xpEarned': history.xpEarned,
      'replayRef': 'replays/match_${history.matchId}.json',
    };

    await _storage.uploadMatchSummary(userId, summary);
  }
}
