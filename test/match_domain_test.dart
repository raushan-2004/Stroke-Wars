import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/features/match/domain/models/guess.dart';
import 'package:stroke_wars/features/match/domain/models/guess_result.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_context.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_result.dart';
import 'package:stroke_wars/features/match/domain/models/match_snapshot.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/match_statistics.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/player_turn.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/match/domain/models/score.dart';
import 'package:stroke_wars/features/match/domain/models/timer_state.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';

void main() {
  group('Match Domain — Unit Tests', () {
    // ────────────────────────────────────────────
    // MatchId / RoundId
    // ────────────────────────────────────────────
    group('Typed IDs', () {
      test('MatchId.generate() produces unique values', () {
        final a = MatchId.generate();
        final b = MatchId.generate();
        expect(a, isNot(equals(b)));
        expect(a.value.length, greaterThan(10));
      });

      test('MatchId equality is value-based', () {
        const id = MatchId('test-uuid');
        expect(id, equals(const MatchId('test-uuid')));
        expect(id, isNot(equals(const MatchId('other-uuid'))));
      });

      test('RoundId round-trips through JSON', () {
        final id = RoundId.generate();
        final json = id.toJson();
        final restored = RoundId.fromJson(json);
        expect(restored, equals(id));
      });
    });

    // ────────────────────────────────────────────
    // Word
    // ────────────────────────────────────────────
    group('Word', () {
      const word = Word(
        id: 'w001',
        text: 'Elephant',
        difficulty: WordDifficulty.medium,
        category: WordCategory.animals,
        hints: ['Large mammal', 'Has a trunk'],
      );

      test('masked returns underscores for letters and spaces for spaces', () {
        const spaceWord = Word(
          id: 'w002',
          text: 'Big Cat',
          difficulty: WordDifficulty.easy,
          category: WordCategory.animals,
        );
        expect(spaceWord.masked, contains(' '));
        expect(spaceWord.masked, contains('_'));
      });

      test('partialReveal(0) returns fully masked word', () {
        final result = word.partialReveal(0);
        expect(result, isNot(contains('E')));
      });

      test('partialReveal reveals the requested number of characters', () {
        final result = word.partialReveal(3);
        final revealed = result
            .split(' ')
            .where((c) => c.length == 1 && c != '_')
            .length;
        expect(revealed, 3);
      });

      test('Word JSON round-trip', () {
        final json = word.toJson();
        final restored = Word.fromJson(json);
        expect(restored.id, word.id);
        expect(restored.difficulty, word.difficulty);
        expect(restored.category, word.category);
        expect(restored.hints, word.hints);
      });

      test('WordDifficulty multipliers are ordered', () {
        expect(
          WordDifficulty.easy.pointMultiplier,
          lessThan(WordDifficulty.medium.pointMultiplier),
        );
        expect(
          WordDifficulty.medium.pointMultiplier,
          lessThan(WordDifficulty.hard.pointMultiplier),
        );
        expect(
          WordDifficulty.hard.pointMultiplier,
          lessThan(WordDifficulty.extreme.pointMultiplier),
        );
      });
    });

    // ────────────────────────────────────────────
    // PlayerSlot
    // ────────────────────────────────────────────
    group('PlayerSlot', () {
      const slot = PlayerSlot(
        slotId: 'slot-1',
        playerId: 'player-uuid',
        displayName: 'Alice',
        role: PlayerRole.guesser,
      );

      test('copyWith changes only specified fields', () {
        final updated = slot.copyWith(totalScore: 150);
        expect(updated.totalScore, 150);
        expect(updated.displayName, slot.displayName);
        expect(updated.role, slot.role);
      });

      test('PlayerSlot JSON round-trip', () {
        final json = slot.toJson();
        final restored = PlayerSlot.fromJson(json);
        expect(restored.slotId, slot.slotId);
        expect(restored.role, slot.role);
        expect(restored.isConnected, slot.isConnected);
      });

      test('PlayerRole.drawer.canDraw is true', () {
        expect(PlayerRole.drawer.canDraw, isTrue);
        expect(PlayerRole.guesser.canDraw, isFalse);
      });

      test('PlayerRole.guesser.canGuess is true', () {
        expect(PlayerRole.guesser.canGuess, isTrue);
        expect(PlayerRole.drawer.canGuess, isFalse);
      });
    });

    // ────────────────────────────────────────────
    // Score
    // ────────────────────────────────────────────
    group('Score', () {
      final roundId = RoundId('round-abc');

      test('Score JSON round-trip', () {
        final score = Score(
          playerId: 'player-1',
          roundId: roundId,
          points: 150,
          guessTimeMs: 3000,
          bonuses: ['time_bonus', 'first_guesser'],
        );
        final json = score.toJson();
        final restored = Score.fromJson(json);
        expect(restored.points, 150);
        expect(restored.bonuses.length, 2);
        expect(restored.guessTimeMs, 3000);
      });
    });

    // ────────────────────────────────────────────
    // TimerState
    // ────────────────────────────────────────────
    group('TimerState', () {
      test('TimerState.initial starts at zero', () {
        final t = TimerState.initial(60);
        expect(t.elapsedSecs, 0);
        expect(t.remainingSecs, 60);
        expect(t.isExpired, isFalse);
        expect(t.progress, 0.0);
      });

      test('isExpired is true when elapsed >= duration', () {
        const t = TimerState(durationSecs: 10, elapsedSecs: 10);
        expect(t.isExpired, isTrue);
        expect(t.remainingSecs, 0);
        expect(t.progress, 1.0);
      });

      test('progress clamps to [0.0, 1.0]', () {
        const t = TimerState(durationSecs: 10, elapsedSecs: 20);
        expect(t.progress, 1.0);
        expect(t.remainingSecs, 0);
      });

      test('TimerState JSON round-trip', () {
        const t = TimerState(
          durationSecs: 80,
          elapsedSecs: 30,
          isRunning: true,
        );
        final json = t.toJson();
        final restored = TimerState.fromJson(json);
        expect(restored.durationSecs, t.durationSecs);
        expect(restored.elapsedSecs, t.elapsedSecs);
        expect(restored.isRunning, t.isRunning);
      });
    });

    // ────────────────────────────────────────────
    // MatchState transitions (via label / isTerminal)
    // ────────────────────────────────────────────
    group('MatchState', () {
      test('isTerminal returns true for finished and cancelled states', () {
        expect(const MatchFinishedState().isTerminal, isTrue);
        expect(const MatchCancelledState().isTerminal, isTrue);
        expect(const DrawingState().isTerminal, isFalse);
      });

      test('isActive returns true during gameplay states', () {
        expect(const DrawingState().isActive, isTrue);
        expect(const GuessingState().isActive, isTrue);
        expect(const WordSelectionState().isActive, isTrue);
        expect(const ScoreboardState().isActive, isFalse);
      });

      test('label is non-empty for all states', () {
        final states = [
          const MatchCreatedState(),
          const MatchWaitingState(),
          const MatchStartingState(),
          const WordSelectionState(),
          const DrawingState(),
          const GuessingState(),
          const RoundFinishedState(),
          const ScoreboardState(),
          const MatchFinishedState(),
          const MatchCancelledState(),
        ];
        for (final s in states) {
          expect(s.label, isNotEmpty);
        }
      });
    });

    // ────────────────────────────────────────────
    // RoundState
    // ────────────────────────────────────────────
    group('RoundState', () {
      test('isInProgress returns true for preparing and active states', () {
        expect(const RoundPreparingState().isInProgress, isTrue);
        expect(const RoundActiveState().isInProgress, isTrue);
        expect(const RoundIdleState().isInProgress, isFalse);
      });

      test('isTerminal returns true for finished and cancelled states', () {
        expect(const RoundFinishedRoundState().isTerminal, isTrue);
        expect(const RoundCancelledState().isTerminal, isTrue);
        expect(const RoundActiveState().isTerminal, isFalse);
      });
    });

    // ────────────────────────────────────────────
    // MatchConfiguration
    // ────────────────────────────────────────────
    group('MatchConfiguration', () {
      test('default configuration has sensible values', () {
        const config = MatchConfiguration();
        expect(config.maxPlayers, 8);
        expect(config.totalRounds, 3);
        expect(config.drawTimeSecs, 80);
        expect(config.difficulty, WordDifficulty.medium);
        expect(config.wordChoiceCount, 3);
      });

      test('roundConfiguration is derived correctly', () {
        const config = MatchConfiguration(
          drawTimeSecs: 60,
          wordChoiceCount: 2,
          enableHints: false,
        );
        final rc = config.roundConfiguration;
        expect(rc.drawTimeSecs, 60);
        expect(rc.wordChoiceCount, 2);
        expect(rc.revealHints, isFalse);
      });

      test('MatchConfiguration JSON round-trip', () {
        const config = MatchConfiguration(
          maxPlayers: 4,
          totalRounds: 5,
          isPrivate: true,
        );
        final json = config.toJson();
        final restored = MatchConfiguration.fromJson(json);
        expect(restored.maxPlayers, 4);
        expect(restored.totalRounds, 5);
        expect(restored.isPrivate, isTrue);
      });
    });

    // ────────────────────────────────────────────
    // PlayerTurn
    // ────────────────────────────────────────────
    group('PlayerTurn', () {
      test('durationMs is calculated correctly', () {
        final start = DateTime(2026, 7, 1, 12, 0, 0);
        final end = start.add(const Duration(seconds: 45));
        final turn = PlayerTurn(
          roundNumber: 1,
          drawerId: 'player-1',
          drawerDisplayName: 'Alice',
          startedAt: start,
          endedAt: end,
          completed: true,
        );
        expect(turn.durationMs, 45000);
      });

      test('durationMs is null while turn is in progress', () {
        final turn = PlayerTurn(
          roundNumber: 1,
          drawerId: 'player-1',
          drawerDisplayName: 'Alice',
          startedAt: DateTime.now(),
        );
        expect(turn.durationMs, isNull);
      });

      test('PlayerTurn JSON round-trip', () {
        final turn = PlayerTurn(
          roundNumber: 2,
          drawerId: 'uuid-abc',
          drawerDisplayName: 'Bob',
          startedAt: DateTime(2026),
          completed: false,
          skipped: true,
          wordsOffered: ['w001', 'w002', 'w003'],
          wordChosenId: null,
        );
        final json = turn.toJson();
        final restored = PlayerTurn.fromJson(json);
        expect(restored.roundNumber, 2);
        expect(restored.skipped, isTrue);
        expect(restored.wordsOffered.length, 3);
      });
    });

    // ────────────────────────────────────────────
    // MatchResult
    // ────────────────────────────────────────────
    group('MatchResult', () {
      test('rankedScores is sorted highest-first', () {
        final result = MatchResult(
          winnerId: 'p2',
          winnerDisplayName: 'Charlie',
          finalScores: {'p1': 100, 'p2': 300, 'p3': 200},
          totalRounds: 3,
          startedAt: DateTime(2026),
          endedAt: DateTime(2026).add(const Duration(minutes: 10)),
        );
        final ranked = result.rankedScores;
        expect(ranked.first.key, 'p2');
        expect(ranked.last.key, 'p1');
      });

      test('positionOf returns correct 1-based rank', () {
        final result = MatchResult(
          winnerId: 'p1',
          winnerDisplayName: 'Alice',
          finalScores: {'p1': 500, 'p2': 300},
          totalRounds: 3,
          startedAt: DateTime(2026),
          endedAt: DateTime(2026).add(const Duration(minutes: 5)),
        );
        expect(result.positionOf('p1'), 1);
        expect(result.positionOf('p2'), 2);
        expect(result.positionOf('unknown'), -1);
      });

      test('durationMs is calculated correctly', () {
        final start = DateTime(2026, 1, 1);
        final end = start.add(const Duration(minutes: 15));
        final result = MatchResult(
          winnerId: 'p1',
          winnerDisplayName: 'Alice',
          finalScores: {'p1': 100},
          totalRounds: 3,
          startedAt: start,
          endedAt: end,
        );
        expect(result.durationMs, 15 * 60 * 1000);
      });
    });

    // ────────────────────────────────────────────
    // MatchStatistics
    // ────────────────────────────────────────────
    group('MatchStatistics', () {
      test('guessAccuracy is 0 with no guesses', () {
        const stats = MatchStatistics(playerId: 'p1', matchId: 'm1');
        expect(stats.guessAccuracy, 0.0);
      });

      test('guessAccuracy calculates correctly', () {
        const stats = MatchStatistics(
          playerId: 'p1',
          matchId: 'm1',
          correctGuesses: 3,
          totalGuesses: 4,
        );
        expect(stats.guessAccuracy, closeTo(75.0, 0.01));
      });

      test('MatchStatistics JSON round-trip', () {
        const stats = MatchStatistics(
          playerId: 'p1',
          matchId: 'm1',
          longestStreak: 5,
          totalPointsEarned: 420,
        );
        final json = stats.toJson();
        final restored = MatchStatistics.fromJson(json);
        expect(restored.longestStreak, 5);
        expect(restored.totalPointsEarned, 420);
      });
    });

    // ────────────────────────────────────────────
    // Match aggregate
    // ────────────────────────────────────────────
    group('Match', () {
      final config = const MatchConfiguration(maxPlayers: 4, totalRounds: 2);
      final slots = [
        const PlayerSlot(
          slotId: 'slot-1',
          playerId: 'player-1',
          displayName: 'Alice',
          role: PlayerRole.host,
        ),
        const PlayerSlot(
          slotId: 'slot-2',
          playerId: 'player-2',
          displayName: 'Bob',
          role: PlayerRole.guesser,
        ),
      ];

      Match buildMatch() => Match(
        id: MatchId.generate(),
        hostId: 'player-1',
        configuration: config,
        players: slots,
        rounds: const [],
        state: const MatchWaitingState(),
        createdAt: DateTime(2026),
      );

      test('connectedPlayers filters disconnected slots', () {
        final match = buildMatch();
        final disconnected = slots[1].copyWith(isConnected: false);
        final updated = match.copyWith(players: [slots[0], disconnected]);
        expect(updated.connectedPlayers.length, 1);
      });

      test('playerByPlayerId finds correct slot', () {
        final match = buildMatch();
        final found = match.playerByPlayerId('player-2');
        expect(found?.displayName, 'Bob');
      });

      test('currentRound returns null when no rounds exist', () {
        final match = buildMatch();
        expect(match.currentRound, isNull);
      });

      test('Match JSON round-trip', () {
        final match = buildMatch();
        final json = match.toJson();
        final restored = Match.fromJson(json);
        expect(restored.id, match.id);
        expect(restored.players.length, match.players.length);
        expect(restored.state.label, match.state.label);
      });
    });

    // ────────────────────────────────────────────
    // MatchContext
    // ────────────────────────────────────────────
    group('MatchContext', () {
      test('MatchContext.from builds correctly from Match', () {
        final match = Match(
          id: MatchId.generate(),
          hostId: 'host',
          configuration: const MatchConfiguration(),
          players: const [
            PlayerSlot(
              slotId: 's1',
              playerId: 'host',
              displayName: 'Host',
              role: PlayerRole.host,
            ),
          ],
          rounds: const [],
          state: const MatchWaitingState(),
          createdAt: DateTime(2026),
        );
        final ctx = MatchContext.from(match);
        expect(ctx.match, equals(match));
        expect(ctx.currentRound, isNull);
        expect(ctx.hasActiveRound, isFalse);
        expect(ctx.hasChosenWord, isFalse);
      });
    });

    // ────────────────────────────────────────────
    // MatchSnapshot
    // ────────────────────────────────────────────
    group('MatchSnapshot', () {
      test('MatchSnapshot.from captures current match state', () {
        final match = Match(
          id: MatchId.generate(),
          hostId: 'host',
          configuration: const MatchConfiguration(),
          players: const [],
          rounds: const [],
          state: const MatchWaitingState(),
          createdAt: DateTime(2026),
        );
        final snapshot = MatchSnapshot.from(match);
        expect(snapshot.matchId, match.id);
        expect(snapshot.matchState, 'waiting');
        expect(snapshot.version, MatchSnapshot.currentVersion);
      });

      test('MatchSnapshot JSON round-trip preserves all fields', () {
        final match = Match(
          id: MatchId.generate(),
          hostId: 'host',
          configuration: const MatchConfiguration(totalRounds: 5),
          players: const [],
          rounds: const [],
          state: const DrawingState(),
          createdAt: DateTime(2026),
        );
        final snapshot = MatchSnapshot.from(match);
        final json = snapshot.toJson();
        final restored = MatchSnapshot.fromJson(json);
        expect(restored.matchId, snapshot.matchId);
        expect(restored.matchState, snapshot.matchState);
        expect(restored.configuration.totalRounds, 5);
      });
    });

    // ────────────────────────────────────────────
    // Guess and GuessResult
    // ────────────────────────────────────────────
    group('Guess', () {
      test('GuessResult.correct.awardsPoints is true', () {
        expect(GuessResult.correct.awardsPoints, isTrue);
        expect(GuessResult.incorrect.awardsPoints, isFalse);
        expect(GuessResult.tooLate.awardsPoints, isFalse);
      });

      test('Guess JSON round-trip', () {
        final guess = Guess(
          playerId: 'p1',
          text: 'Dragon',
          submittedAt: DateTime(2026),
          result: GuessResult.correct,
          guessTimeMs: 4500,
        );
        final json = guess.toJson();
        final restored = Guess.fromJson(json);
        expect(restored.text, 'Dragon');
        expect(restored.result, GuessResult.correct);
        expect(restored.guessTimeMs, 4500);
      });
    });

    // ────────────────────────────────────────────
    // Round
    // ────────────────────────────────────────────
    group('Round', () {
      test('correctGuessCount counts only correct guesses', () {
        final guesses = [
          Guess(
            playerId: 'p1',
            text: 'right',
            submittedAt: DateTime(2026),
            result: GuessResult.correct,
          ),
          Guess(
            playerId: 'p2',
            text: 'wrong',
            submittedAt: DateTime(2026),
            result: GuessResult.incorrect,
          ),
          Guess(
            playerId: 'p3',
            text: 'right',
            submittedAt: DateTime(2026),
            result: GuessResult.correct,
          ),
        ];
        final round = Round(
          id: RoundId.generate(),
          matchId: MatchId.generate(),
          roundNumber: 1,
          state: const RoundActiveState(),
          drawerSlotId: 'slot-drawer',
          configuration: const MatchConfiguration().roundConfiguration,
          guesses: guesses,
        );
        expect(round.correctGuessCount, 2);
      });
    });
  });
}
