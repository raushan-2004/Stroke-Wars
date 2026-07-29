/// Configuration for a single round within a match.
class RoundConfiguration {
  /// Creates an immutable [RoundConfiguration].
  const RoundConfiguration({
    this.drawTimeSecs = 80,
    this.guessTimeSecs = 80,
    this.wordChoiceCount = 3,
    this.revealHints = true,
    this.hintCount = 2,
  });

  /// Creates a [RoundConfiguration] from a JSON map.
  factory RoundConfiguration.fromJson(Map<String, dynamic> json) =>
      RoundConfiguration(
        drawTimeSecs: json['drawTimeSecs'] as int? ?? 80,
        guessTimeSecs: json['guessTimeSecs'] as int? ?? 80,
        wordChoiceCount: json['wordChoiceCount'] as int? ?? 3,
        revealHints: json['revealHints'] as bool? ?? true,
        hintCount: json['hintCount'] as int? ?? 2,
      );

  /// Duration (in seconds) the drawer has to draw.
  final int drawTimeSecs;

  /// Duration (in seconds) guessers have to submit correct answers.
  final int guessTimeSecs;

  /// How many word options are presented to the drawer.
  final int wordChoiceCount;

  /// Whether partial word hints are progressively revealed.
  final bool revealHints;

  /// How many letters are revealed as hints.
  final int hintCount;

  /// Returns a copy with the specified fields replaced.
  RoundConfiguration copyWith({
    int? drawTimeSecs,
    int? guessTimeSecs,
    int? wordChoiceCount,
    bool? revealHints,
    int? hintCount,
  }) => RoundConfiguration(
    drawTimeSecs: drawTimeSecs ?? this.drawTimeSecs,
    guessTimeSecs: guessTimeSecs ?? this.guessTimeSecs,
    wordChoiceCount: wordChoiceCount ?? this.wordChoiceCount,
    revealHints: revealHints ?? this.revealHints,
    hintCount: hintCount ?? this.hintCount,
  );

  /// Converts this [RoundConfiguration] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'drawTimeSecs': drawTimeSecs,
    'guessTimeSecs': guessTimeSecs,
    'wordChoiceCount': wordChoiceCount,
    'revealHints': revealHints,
    'hintCount': hintCount,
  };

  @override
  bool operator ==(Object other) =>
      other is RoundConfiguration &&
      other.drawTimeSecs == drawTimeSecs &&
      other.guessTimeSecs == guessTimeSecs &&
      other.wordChoiceCount == wordChoiceCount &&
      other.revealHints == revealHints &&
      other.hintCount == hintCount;

  @override
  int get hashCode => Object.hash(
    drawTimeSecs,
    guessTimeSecs,
    wordChoiceCount,
    revealHints,
    hintCount,
  );
}
