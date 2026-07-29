/// Outcome of a single guess attempt.
enum GuessResult {
  /// The guess exactly matched the target word.
  correct,

  /// The guess did not match the target word.
  incorrect,

  /// The timer expired before this player guessed correctly.
  tooLate,

  /// The player chose not to guess or was automatically skipped.
  skipped,
}

/// Extension providing human-readable labels for [GuessResult].
extension GuessResultLabel on GuessResult {
  /// Returns the display label for this result.
  String get label => switch (this) {
    GuessResult.correct => 'Correct!',
    GuessResult.incorrect => 'Wrong',
    GuessResult.tooLate => 'Too Late',
    GuessResult.skipped => 'Skipped',
  };

  /// Returns true if this result awards the guesser points.
  bool get awardsPoints => this == GuessResult.correct;
}
