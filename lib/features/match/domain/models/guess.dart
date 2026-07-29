import 'package:stroke_wars/features/match/domain/models/guess_result.dart';

/// An immutable record of a single guess attempt by a player.
class Guess {
  /// Creates an immutable [Guess].
  const Guess({
    required this.playerId,
    required this.text,
    required this.submittedAt,
    required this.result,
    this.guessTimeMs = 0,
  });

  /// Creates a [Guess] from a JSON map.
  factory Guess.fromJson(Map<String, dynamic> json) => Guess(
    playerId: json['playerId'] as String,
    text: json['text'] as String,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
    result: GuessResult.values.firstWhere((r) => r.name == json['result']),
    guessTimeMs: json['guessTimeMs'] as int? ?? 0,
  );

  /// The guessing player's UUID.
  final String playerId;

  /// The text the player submitted.
  final String text;

  /// When this guess was submitted.
  final DateTime submittedAt;

  /// The outcome of this guess.
  final GuessResult result;

  /// Elapsed milliseconds from round start to this guess.
  final int guessTimeMs;

  /// Returns a copy with the specified fields replaced.
  Guess copyWith({
    String? playerId,
    String? text,
    DateTime? submittedAt,
    GuessResult? result,
    int? guessTimeMs,
  }) => Guess(
    playerId: playerId ?? this.playerId,
    text: text ?? this.text,
    submittedAt: submittedAt ?? this.submittedAt,
    result: result ?? this.result,
    guessTimeMs: guessTimeMs ?? this.guessTimeMs,
  );

  /// Converts this [Guess] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'text': text,
    'submittedAt': submittedAt.toIso8601String(),
    'result': result.name,
    'guessTimeMs': guessTimeMs,
  };

  @override
  bool operator ==(Object other) =>
      other is Guess &&
      other.playerId == playerId &&
      other.submittedAt == submittedAt;

  @override
  int get hashCode => Object.hash(playerId, submittedAt);

  @override
  String toString() =>
      'Guess(player=$playerId, text=$text, result=${result.name})';
}
