import 'dart:math';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';

/// Simulates automated bot guessers submitting correct/incorrect guesses during sketching.
class PracticeBotEngine {
  /// Creates a [PracticeBotEngine].
  PracticeBotEngine({
    required this.bots,
    required this.targetWord,
    required this.incorrectWordPool,
    Random? random,
  }) : random = random ?? Random() {
    // Determine deterministic correct and incorrect timing offsets for each bot
    for (final botId in bots) {
      _correctGuessTimes[botId] = 10 + this.random.nextInt(30);
      _nextIncorrectGuessTimes[botId] = 3 + this.random.nextInt(8);
    }
  }

  /// List of simulated player IDs.
  final List<String> bots;

  /// The target correct word.
  final String targetWord;

  /// Pool of potential incorrect guesses.
  final List<String> incorrectWordPool;

  /// Generator for randomized profiles.
  final Random random;

  final Map<String, int> _correctGuessTimes = {};
  final Map<String, int> _nextIncorrectGuessTimes = {};
  final Set<String> _guessedCorrectly = {};

  /// Ticks the simulated timing and returns a list of guess commands to dispatch.
  List<MatchCommand> tick(int elapsedSecs, MatchId matchId) {
    final List<MatchCommand> commands = [];

    for (final botId in bots) {
      if (_guessedCorrectly.contains(botId)) continue;

      // Check if bot should guess correctly
      final targetCorrectTime = _correctGuessTimes[botId] ?? 999;
      if (elapsedSecs >= targetCorrectTime) {
        _guessedCorrectly.add(botId);
        commands.add(
          SubmitGuessCommand(
            matchId: matchId,
            playerId: botId,
            guessText: targetWord,
          ),
        );
        continue;
      }

      // Check if bot should submit a wrong guess
      final targetIncorrectTime = _nextIncorrectGuessTimes[botId] ?? 999;
      if (elapsedSecs >= targetIncorrectTime) {
        _nextIncorrectGuessTimes[botId] = elapsedSecs + 8 + random.nextInt(12);

        final guessWord = incorrectWordPool.isNotEmpty
            ? incorrectWordPool[random.nextInt(incorrectWordPool.length)]
            : 'sketch';

        // Ensure we don't accidentally guess the correct word as an incorrect guess
        if (guessWord.trim().toLowerCase() != targetWord.trim().toLowerCase()) {
          commands.add(
            SubmitGuessCommand(
              matchId: matchId,
              playerId: botId,
              guessText: guessWord,
            ),
          );
        }
      }
    }

    return commands;
  }
}
