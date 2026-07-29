/// The outcome of a completed [Match].
class MatchResult {
  /// Creates an immutable [MatchResult].
  const MatchResult({
    required this.winnerId,
    required this.winnerDisplayName,
    required this.finalScores,
    required this.totalRounds,
    required this.startedAt,
    required this.endedAt,
  });

  /// Creates a [MatchResult] from a JSON map.
  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
    winnerId: json['winnerId'] as String,
    winnerDisplayName: json['winnerDisplayName'] as String,
    finalScores: Map<String, int>.from(json['finalScores'] as Map),
    totalRounds: json['totalRounds'] as int,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: DateTime.parse(json['endedAt'] as String),
  );

  /// UUID of the player who won.
  final String winnerId;

  /// Display name of the winning player.
  final String winnerDisplayName;

  /// Map of playerId → total score at match end.
  final Map<String, int> finalScores;

  /// Number of rounds that were played.
  final int totalRounds;

  /// When the match started.
  final DateTime startedAt;

  /// When the match ended.
  final DateTime endedAt;

  /// Duration of the entire match in milliseconds.
  int get durationMs => endedAt.difference(startedAt).inMilliseconds;

  /// Returns an ordered list of (playerId, score) pairs, highest first.
  List<MapEntry<String, int>> get rankedScores =>
      finalScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  /// Returns the position (1-based) of the player with [playerId].
  int positionOf(String playerId) {
    final ranked = rankedScores;
    for (var i = 0; i < ranked.length; i++) {
      if (ranked[i].key == playerId) return i + 1;
    }
    return -1;
  }

  /// Returns a copy with the specified fields replaced.
  MatchResult copyWith({
    String? winnerId,
    String? winnerDisplayName,
    Map<String, int>? finalScores,
    int? totalRounds,
    DateTime? startedAt,
    DateTime? endedAt,
  }) => MatchResult(
    winnerId: winnerId ?? this.winnerId,
    winnerDisplayName: winnerDisplayName ?? this.winnerDisplayName,
    finalScores: finalScores ?? this.finalScores,
    totalRounds: totalRounds ?? this.totalRounds,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
  );

  /// Converts this [MatchResult] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'winnerId': winnerId,
    'winnerDisplayName': winnerDisplayName,
    'finalScores': finalScores,
    'totalRounds': totalRounds,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is MatchResult &&
      other.winnerId == winnerId &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(winnerId, endedAt);

  @override
  String toString() =>
      'MatchResult(winner=$winnerDisplayName, rounds=$totalRounds)';
}
