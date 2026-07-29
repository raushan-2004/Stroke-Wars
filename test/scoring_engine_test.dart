import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/score.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

void main() {
  const engine = ScoringEngine();
  const config = MatchConfiguration(drawTimeSecs: 80);
  final roundId = RoundId('test-round');

  group('ScoringEngine', () {
    group('scoreCorrectGuess()', () {
      test('base points are awarded for correct guess', () {
        final result = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 40000, // halfway through 80 second timer
          config: config,
          isFirstGuesser: false,
        );
        expect(result.points, greaterThanOrEqualTo(ScoreRules.baseCorrectGuess));
      });

      test('early guess earns time bonus', () {
        final earlyResult = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 1000, // guessed very early
          config: config,
          isFirstGuesser: false,
        );
        final lateResult = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 79000, // guessed very late
          config: config,
          isFirstGuesser: false,
        );
        expect(earlyResult.points, greaterThan(lateResult.points));
        expect(earlyResult.bonuses, contains('time_bonus'));
      });

      test('first guesser earns additional bonus', () {
        final firstResult = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 30000,
          config: config,
          isFirstGuesser: true,
        );
        final secondResult = engine.scoreCorrectGuess(
          playerId: 'p2',
          roundId: roundId,
          guessTimeMs: 30000,
          config: config,
          isFirstGuesser: false,
        );
        expect(firstResult.points, greaterThan(secondResult.points));
        expect(firstResult.bonuses, contains('first_guesser'));
      });

      test('difficulty multiplier increases score', () {
        final easyResult = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 40000,
          config: config,
          isFirstGuesser: false,
          difficulty: WordDifficulty.easy,
        );
        final extremeResult = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 40000,
          config: config,
          isFirstGuesser: false,
          difficulty: WordDifficulty.extreme,
        );
        expect(extremeResult.points, greaterThan(easyResult.points));
      });

      test('all bonuses stack correctly for best case', () {
        final perfect = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 500, // almost instant
          config: config,
          isFirstGuesser: true,
          difficulty: WordDifficulty.extreme,
        );
        // Base(100) + TimeBonus(~50) + FirstGuesser(30) all × 2.0
        expect(perfect.points, greaterThan(300));
        expect(perfect.bonuses, contains('time_bonus'));
        expect(perfect.bonuses, contains('first_guesser'));
        expect(perfect.bonuses, contains('difficulty_extreme'));
      });

      test('guessTimeMs is stored in result', () {
        final result = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 12345,
          config: config,
          isFirstGuesser: false,
        );
        expect(result.guessTimeMs, 12345);
      });

      test('toScore() converts to Score domain model', () {
        final result = engine.scoreCorrectGuess(
          playerId: 'p1',
          roundId: roundId,
          guessTimeMs: 30000,
          config: config,
          isFirstGuesser: false,
        );
        final score = result.toScore();
        expect(score, isA<Score>());
        expect(score.playerId, 'p1');
        expect(score.points, result.points);
      });
    });

    group('scoreParticipation()', () {
      test('awards participation points', () {
        final result = engine.scoreParticipation(
          playerId: 'p1',
          roundId: roundId,
        );
        expect(result.points, ScoreRules.participationPoints);
        expect(result.bonuses, contains('participation'));
        expect(result.guessTimeMs, isNull);
      });
    });

    group('scoreDrawer()', () {
      test('returns null when no one guessed correctly', () {
        final result = engine.scoreDrawer(
          drawerId: 'drawer',
          roundId: roundId,
          correctGuessCount: 0,
        );
        expect(result, isNull);
      });

      test('awards drawer bonus proportional to correct guesses', () {
        final oneGuesser = engine.scoreDrawer(
          drawerId: 'drawer',
          roundId: roundId,
          correctGuessCount: 1,
        );
        final threeGuessers = engine.scoreDrawer(
          drawerId: 'drawer',
          roundId: roundId,
          correctGuessCount: 3,
        );
        expect(threeGuessers!.points, greaterThan(oneGuesser!.points));
        expect(oneGuesser.bonuses, contains('drawer_bonus'));
        expect(oneGuesser.isDrawerBonus, isTrue);
      });

      test('difficulty multiplier applies to drawer bonus', () {
        final easyBonus = engine.scoreDrawer(
          drawerId: 'drawer',
          roundId: roundId,
          correctGuessCount: 2,
          difficulty: WordDifficulty.easy,
        );
        final hardBonus = engine.scoreDrawer(
          drawerId: 'drawer',
          roundId: roundId,
          correctGuessCount: 2,
          difficulty: WordDifficulty.hard,
        );
        expect(hardBonus!.points, greaterThan(easyBonus!.points));
      });
    });

    group('aggregateScores()', () {
      test('aggregates multiple scores by playerId', () {
        final roundId2 = RoundId('round-2');
        final scores = [
          Score(playerId: 'p1', roundId: roundId, points: 100),
          Score(playerId: 'p2', roundId: roundId, points: 200),
          Score(playerId: 'p1', roundId: roundId2, points: 150),
        ];
        final totals = engine.aggregateScores(scores);
        expect(totals['p1'], 250);
        expect(totals['p2'], 200);
      });

      test('returns empty map for empty score list', () {
        expect(engine.aggregateScores([]), isEmpty);
      });

      test('single player aggregates correctly', () {
        final scores = [
          Score(playerId: 'p1', roundId: roundId, points: 75),
          Score(playerId: 'p1', roundId: RoundId('r2'), points: 50),
        ];
        final totals = engine.aggregateScores(scores);
        expect(totals['p1'], 125);
      });
    });

    group('VictoryRules.determineWinner()', () {
      const victoryRules = VictoryRules();

      test('returns winner when one player leads', () {
        final winner = victoryRules.determineWinner({'p1': 500, 'p2': 300, 'p3': 100});
        expect(winner, 'p1');
      });

      test('returns null when two players tie', () {
        final winner = victoryRules.determineWinner({'p1': 300, 'p2': 300});
        expect(winner, isNull);
      });

      test('returns null for empty scores', () {
        expect(victoryRules.determineWinner({}), isNull);
      });

      test('isMatchComplete returns true when rounds exhausted', () {
        const config = MatchConfiguration(totalRounds: 3);
        expect(victoryRules.isMatchComplete(3, config), isTrue);
        expect(victoryRules.isMatchComplete(2, config), isFalse);
      });
    });

    group('WordRules.isCorrectGuess()', () {
      const wordRules = WordRules();

      test('case-insensitive match returns true', () {
        expect(wordRules.isCorrectGuess('DRAGON', 'dragon'), isTrue);
        expect(wordRules.isCorrectGuess('Dragon', 'dragon'), isTrue);
      });

      test('trimmed match returns true', () {
        expect(wordRules.isCorrectGuess(' dragon ', 'dragon'), isTrue);
      });

      test('wrong word returns false', () {
        expect(wordRules.isCorrectGuess('cat', 'dragon'), isFalse);
      });

      test('empty guess returns false', () {
        expect(wordRules.isValidGuessText(''), isFalse);
        expect(wordRules.isValidGuessText('   '), isFalse);
        expect(wordRules.isValidGuessText('word'), isTrue);
      });
    });
  });
}
