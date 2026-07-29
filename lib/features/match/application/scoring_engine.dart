import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/score.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

/// Result of a scoring calculation for a single player in a round.
class ScoringResult {
  /// Creates a [ScoringResult].
  const ScoringResult({
    required this.playerId,
    required this.roundId,
    required this.points,
    required this.bonuses,
    this.guessTimeMs,
    this.isDrawerBonus = false,
  });

  /// The recipient player.
  final String playerId;

  /// The round these points belong to.
  final RoundId roundId;

  /// Total points calculated.
  final int points;

  /// Named bonuses applied.
  final List<String> bonuses;

  /// Milliseconds to guess (null for drawer bonuses).
  final int? guessTimeMs;

  /// True if this is a drawer rather than guesser reward.
  final bool isDrawerBonus;

  /// Converts to a [Score] domain model.
  Score toScore() => Score(
    playerId: playerId,
    roundId: roundId,
    points: points,
    guessTimeMs: guessTimeMs,
    bonuses: bonuses,
    isDrawerBonus: isDrawerBonus,
  );
}

/// Pure-function scoring engine.
///
/// All methods are stateless — no I/O, no side effects.
/// Future combo/streak bonuses are additive extensions, not rewrites.
class ScoringEngine {
  /// Creates a [ScoringEngine] with the given [rules].
  const ScoringEngine({this.rules = const ScoreRules()});

  /// Scoring sub-rules reference.
  final ScoreRules rules;

  // ───────────────────────────────────────────────────────────────────────────
  // Guesser scoring
  // ───────────────────────────────────────────────────────────────────────────

  /// Calculates the score for a player who guessed correctly.
  ///
  /// [guessTimeMs] is elapsed milliseconds from round start.
  /// [drawTimeSecs] is the total allowed draw time.
  /// [isFirstGuesser] grants an additional bonus.
  /// [difficulty] applies a score multiplier.
  ScoringResult scoreCorrectGuess({
    required String playerId,
    required RoundId roundId,
    required int guessTimeMs,
    required MatchConfiguration config,
    required bool isFirstGuesser,
    WordDifficulty difficulty = WordDifficulty.medium,
  }) {
    final bonuses = <String>[];
    var points = ScoreRules.baseCorrectGuess;

    // Time bonus: linear decay from maxTimeBonus → 0 over the draw period
    final drawTimeMs = config.drawTimeSecs * 1000;
    if (drawTimeMs > 0 && guessTimeMs < drawTimeMs) {
      final fraction = 1.0 - (guessTimeMs / drawTimeMs);
      final timeBonus = (ScoreRules.maxTimeBonus * fraction).round();
      if (timeBonus > 0) {
        points += timeBonus;
        bonuses.add('time_bonus');
      }
    }

    // First guesser bonus
    if (isFirstGuesser) {
      points += ScoreRules.firstGuesserBonus;
      bonuses.add('first_guesser');
    }

    // Difficulty multiplier
    final multiplied = (points * difficulty.pointMultiplier).round();
    if (multiplied != points) bonuses.add('difficulty_${difficulty.name}');
    points = multiplied;

    return ScoringResult(
      playerId: playerId,
      roundId: roundId,
      points: points,
      bonuses: bonuses,
      guessTimeMs: guessTimeMs,
    );
  }

  /// Calculates participation points for a player who guessed but was wrong.
  ScoringResult scoreParticipation({
    required String playerId,
    required RoundId roundId,
  }) => ScoringResult(
    playerId: playerId,
    roundId: roundId,
    points: ScoreRules.participationPoints,
    bonuses: const ['participation'],
    guessTimeMs: null,
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Drawer scoring
  // ───────────────────────────────────────────────────────────────────────────

  /// Calculates the drawer's bonus based on how many guessers were correct.
  ///
  /// Returns null if no one guessed correctly.
  ScoringResult? scoreDrawer({
    required String drawerId,
    required RoundId roundId,
    required int correctGuessCount,
    WordDifficulty difficulty = WordDifficulty.medium,
  }) {
    if (!rules.canAwardDrawerBonus(correctGuessCount)) return null;
    final base =
        ScoreRules.drawerBonusPerGuesser * correctGuessCount;
    final total = (base * difficulty.pointMultiplier).round();
    return ScoringResult(
      playerId: drawerId,
      roundId: roundId,
      points: total,
      bonuses: const ['drawer_bonus'],
      guessTimeMs: null,
      isDrawerBonus: true,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Aggregate totals
  // ───────────────────────────────────────────────────────────────────────────

  /// Aggregates [scores] into a map of playerId → cumulative total.
  Map<String, int> aggregateScores(List<Score> scores) {
    final totals = <String, int>{};
    for (final score in scores) {
      totals[score.playerId] = (totals[score.playerId] ?? 0) + score.points;
    }
    return totals;
  }
}
