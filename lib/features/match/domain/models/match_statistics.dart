/// Cumulative statistics for a player across a single match.
class MatchStatistics {
  /// Creates an immutable [MatchStatistics].
  const MatchStatistics({
    required this.playerId,
    required this.matchId,
    this.correctGuesses = 0,
    this.totalGuesses = 0,
    this.avgGuessTimeMs = 0,
    this.roundsWon = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
    this.totalPointsEarned = 0,
    this.wordsDrawn = 0,
    this.wordsGuessedCorrectly = 0,
  });

  /// Creates a [MatchStatistics] from a JSON map.
  factory MatchStatistics.fromJson(Map<String, dynamic> json) =>
      MatchStatistics(
        playerId: json['playerId'] as String,
        matchId: json['matchId'] as String,
        correctGuesses: json['correctGuesses'] as int? ?? 0,
        totalGuesses: json['totalGuesses'] as int? ?? 0,
        avgGuessTimeMs: json['avgGuessTimeMs'] as int? ?? 0,
        roundsWon: json['roundsWon'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        totalPointsEarned: json['totalPointsEarned'] as int? ?? 0,
        wordsDrawn: json['wordsDrawn'] as int? ?? 0,
        wordsGuessedCorrectly: json['wordsGuessedCorrectly'] as int? ?? 0,
      );

  /// The player these statistics belong to.
  final String playerId;

  /// The match these statistics were recorded for.
  final String matchId;

  /// Number of correct guesses during the match.
  final int correctGuesses;

  /// Total number of guess attempts during the match.
  final int totalGuesses;

  /// Average time to correct guess, in milliseconds.
  final int avgGuessTimeMs;

  /// Number of rounds where this player had the highest score.
  final int roundsWon;

  /// Longest consecutive correct-guess streak.
  final int longestStreak;

  /// Current streak at match end.
  final int currentStreak;

  /// Total points earned across all rounds.
  final int totalPointsEarned;

  /// Number of times this player was the drawer.
  final int wordsDrawn;

  /// Number of words this player guessed correctly as a guesser.
  final int wordsGuessedCorrectly;

  /// Guess accuracy as a percentage [0–100].
  double get guessAccuracy =>
      totalGuesses > 0 ? (correctGuesses / totalGuesses) * 100 : 0;

  /// Returns a copy with the specified fields replaced.
  MatchStatistics copyWith({
    String? playerId,
    String? matchId,
    int? correctGuesses,
    int? totalGuesses,
    int? avgGuessTimeMs,
    int? roundsWon,
    int? longestStreak,
    int? currentStreak,
    int? totalPointsEarned,
    int? wordsDrawn,
    int? wordsGuessedCorrectly,
  }) => MatchStatistics(
    playerId: playerId ?? this.playerId,
    matchId: matchId ?? this.matchId,
    correctGuesses: correctGuesses ?? this.correctGuesses,
    totalGuesses: totalGuesses ?? this.totalGuesses,
    avgGuessTimeMs: avgGuessTimeMs ?? this.avgGuessTimeMs,
    roundsWon: roundsWon ?? this.roundsWon,
    longestStreak: longestStreak ?? this.longestStreak,
    currentStreak: currentStreak ?? this.currentStreak,
    totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
    wordsDrawn: wordsDrawn ?? this.wordsDrawn,
    wordsGuessedCorrectly: wordsGuessedCorrectly ?? this.wordsGuessedCorrectly,
  );

  /// Converts this [MatchStatistics] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'matchId': matchId,
    'correctGuesses': correctGuesses,
    'totalGuesses': totalGuesses,
    'avgGuessTimeMs': avgGuessTimeMs,
    'roundsWon': roundsWon,
    'longestStreak': longestStreak,
    'currentStreak': currentStreak,
    'totalPointsEarned': totalPointsEarned,
    'wordsDrawn': wordsDrawn,
    'wordsGuessedCorrectly': wordsGuessedCorrectly,
  };

  @override
  bool operator ==(Object other) =>
      other is MatchStatistics &&
      other.playerId == playerId &&
      other.matchId == matchId;

  @override
  int get hashCode => Object.hash(playerId, matchId);

  @override
  String toString() =>
      'MatchStatistics(player=$playerId, points=$totalPointsEarned, '
      'accuracy=${guessAccuracy.toStringAsFixed(1)}%)';
}
