import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_history.freezed.dart';
part 'match_history.g.dart';

/// Historical record of a completed game match.
@freezed
class MatchHistory with _$MatchHistory {
  /// Creates a [MatchHistory] entry.
  const factory MatchHistory({
    required String matchId,
    required DateTime playedAt,
    required int duration, // in seconds
    required String gameMode, // online, lan, bluetooth, offline
    required String winner, // winner display name
    required int xpEarned,
  }) = _MatchHistory;

  /// Creates a [MatchHistory] from JSON map.
  factory MatchHistory.fromJson(Map<String, dynamic> json) =>
      _$MatchHistoryFromJson(json);
}
