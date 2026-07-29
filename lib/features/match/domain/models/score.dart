import 'package:stroke_wars/features/match/domain/models/round_id.dart';

/// An immutable scoring record awarded to a player during a round.
class Score {
  /// Creates an immutable [Score].
  const Score({
    required this.playerId,
    required this.roundId,
    required this.points,
    this.guessTimeMs,
    this.bonuses = const [],
    this.isDrawerBonus = false,
  });

  /// Creates a [Score] from a JSON map.
  factory Score.fromJson(Map<String, dynamic> json) => Score(
    playerId: json['playerId'] as String,
    roundId: RoundId(json['roundId'] as String),
    points: json['points'] as int,
    guessTimeMs: json['guessTimeMs'] as int?,
    bonuses: (json['bonuses'] as List<dynamic>).cast<String>(),
    isDrawerBonus: json['isDrawerBonus'] as bool? ?? false,
  );

  /// The player receiving these points.
  final String playerId;

  /// The round this score belongs to.
  final RoundId roundId;

  /// Total points awarded.
  final int points;

  /// How many milliseconds after round start the player guessed correctly.
  /// Null for drawer bonuses or participation points.
  final int? guessTimeMs;

  /// Named bonuses applied (e.g. 'time_bonus', 'first_guess', 'drawer_bonus').
  final List<String> bonuses;

  /// True if this score represents a drawer reward rather than guesser reward.
  final bool isDrawerBonus;

  /// Returns a copy with the specified fields replaced.
  Score copyWith({
    String? playerId,
    RoundId? roundId,
    int? points,
    int? guessTimeMs,
    List<String>? bonuses,
    bool? isDrawerBonus,
  }) => Score(
    playerId: playerId ?? this.playerId,
    roundId: roundId ?? this.roundId,
    points: points ?? this.points,
    guessTimeMs: guessTimeMs ?? this.guessTimeMs,
    bonuses: bonuses ?? this.bonuses,
    isDrawerBonus: isDrawerBonus ?? this.isDrawerBonus,
  );

  /// Converts this [Score] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'roundId': roundId.value,
    'points': points,
    'guessTimeMs': guessTimeMs,
    'bonuses': bonuses,
    'isDrawerBonus': isDrawerBonus,
  };

  @override
  bool operator ==(Object other) =>
      other is Score &&
      other.playerId == playerId &&
      other.roundId == roundId;

  @override
  int get hashCode => Object.hash(playerId, roundId);

  @override
  String toString() =>
      'Score(player=$playerId, points=$points, bonuses=$bonuses)';
}
