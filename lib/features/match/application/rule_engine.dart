import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';

/// Rules governing turn rotation and drawer eligibility.
class TurnRules {
  /// Creates a [TurnRules] instance.
  const TurnRules();

  /// Returns true if [slot] is eligible to be the next drawer.
  bool isEligibleDrawer(PlayerSlot slot) => slot.isConnected;

  /// Returns the minimum number of connected players required to continue.
  int minimumPlayersToResume(MatchConfiguration config) => config.minPlayers;
}

/// Rules governing point calculation.
class ScoreRules {
  /// Creates a [ScoreRules] instance.
  const ScoreRules();

  /// Base points for a correct guess.
  static const int baseCorrectGuess = 100;

  /// Maximum time bonus points (awarded for fastest guess).
  static const int maxTimeBonus = 50;

  /// Points awarded to the drawer per correct guesser.
  static const int drawerBonusPerGuesser = 20;

  /// Points awarded just for participating (incorrect but tried).
  static const int participationPoints = 5;

  /// Bonus awarded to the first player who guesses correctly.
  static const int firstGuesserBonus = 30;

  /// Whether a drawer bonus can be awarded this round.
  bool canAwardDrawerBonus(int correctGuessCount) => correctGuessCount > 0;
}

/// Rules governing word presentation and selection.
class WordRules {
  /// Creates a [WordRules] instance.
  const WordRules();

  /// Maximum number of word options the drawer may be shown.
  static const int maxWordChoices = 5;

  /// Minimum number of word options the drawer must be shown.
  static const int minWordChoices = 1;

  /// Whether the given [wordText] is a valid guess (non-empty, trimmed).
  bool isValidGuessText(String wordText) => wordText.trim().isNotEmpty;

  /// Returns true if [guess] matches [target] (case-insensitive, trimmed).
  bool isCorrectGuess(String guess, String target) =>
      guess.trim().toLowerCase() == target.trim().toLowerCase();
}

/// Rules determining match victory conditions.
class VictoryRules {
  /// Creates a [VictoryRules] instance.
  const VictoryRules();

  /// Returns the [slotId] of the winner from the final [scores] map.
  /// Returns null for a draw.
  String? determineWinner(Map<String, int> scores) {
    if (scores.isEmpty) return null;
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    // Draw check — if two players have the same score, no winner
    if (sorted.length > 1 && sorted[1].value == top.value) return null;
    return top.key;
  }

  /// Returns true if all rounds have been completed.
  bool isMatchComplete(int completedRounds, MatchConfiguration config) =>
      completedRounds >= config.totalRounds;

  /// Returns true if the match should continue despite disconnections.
  bool canContinueWithDisconnections(
    int connectedCount,
    MatchConfiguration config,
  ) => connectedCount >= config.minPlayers;
}

/// Rules validating match configuration values.
class ConfigurationRules {
  /// Creates a [ConfigurationRules] instance.
  const ConfigurationRules();

  /// Absolute minimum allowed round draw time (seconds).
  static const int minDrawTimeSecs = 10;

  /// Absolute maximum allowed round draw time (seconds).
  static const int maxDrawTimeSecs = 300;

  /// Absolute minimum allowed player count.
  static const int minPlayers = 2;

  /// Absolute maximum allowed player count.
  static const int maxPlayers = 16;

  /// Maximum rounds per match.
  static const int maxRounds = 20;

  /// Returns true if [value] is within [min] and [max] inclusive.
  bool inRange(int value, int min, int max) => value >= min && value <= max;
}

/// Facade combining all rule sub-engines.
///
/// [MatchController] interacts with [RuleEngine] rather than each
/// sub-rule class directly. Future game modes swap the relevant sub-rules.
class RuleEngine {
  /// Creates a [RuleEngine] with all sub-rules.
  const RuleEngine({
    this.turnRules = const TurnRules(),
    this.scoreRules = const ScoreRules(),
    this.wordRules = const WordRules(),
    this.victoryRules = const VictoryRules(),
    this.configurationRules = const ConfigurationRules(),
  });

  /// Rules for turn rotation and drawer eligibility.
  final TurnRules turnRules;

  /// Rules for scoring and bonuses.
  final ScoreRules scoreRules;

  /// Rules for word selection and guess matching.
  final WordRules wordRules;

  /// Rules for determining the match winner.
  final VictoryRules victoryRules;

  /// Rules for validating configuration values.
  final ConfigurationRules configurationRules;
}
