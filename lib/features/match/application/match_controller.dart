import 'package:stroke_wars/core/utils/uuid.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/turn_manager.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/guess.dart';
import 'package:stroke_wars/features/match/domain/models/guess_result.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_context.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_result.dart';
import 'package:stroke_wars/features/match/domain/models/match_snapshot.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/player_turn.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';

/// Plain Dart orchestrator for the match domain.
///
/// [MatchController] has **no dependency on Riverpod or Flutter**. It owns
/// the [Match] aggregate, executes [MatchCommand]s, validates transitions
/// via [MatchValidator], delegates rules to [RuleEngine], and publishes
/// [MatchEvent]s through [MatchEventDispatcher].
///
/// Riverpod integration is a thin adapter layer added separately.
///
/// Architecture:
/// ```
/// UI → Riverpod Provider → MatchController (Plain Dart) → Game Domain
/// ```
class MatchController {
  /// Creates a [MatchController].
  MatchController({
    required this.dispatcher,
    required this.validator,
    required this.rules,
    required this.scoring,
    required this.wordSelector,
  });

  /// Event output channel.
  final MatchEventDispatcher dispatcher;

  /// Pre-mutation validation.
  final MatchValidator validator;

  /// Gameplay rule set.
  final RuleEngine rules;

  /// Scoring calculations.
  final ScoringEngine scoring;

  /// Word selection logic.
  final WordSelector wordSelector;

  Match? _match;
  TurnManager? _turnManager;

  // ───────────────────────────────────────────────────────────────────────────
  // Queries
  // ───────────────────────────────────────────────────────────────────────────

  /// The current match, or null if none is active.
  Match? get match => _match;

  /// Current [MatchContext], or null if no match is loaded.
  MatchContext? get context =>
      _match != null ? MatchContext.from(_match!) : null;

  /// True if a match is currently loaded and active.
  bool get hasActiveMatch =>
      _match != null && !_match!.state.isTerminal;

  // ───────────────────────────────────────────────────────────────────────────
  // Command execution
  // ───────────────────────────────────────────────────────────────────────────

  /// Executes a [MatchCommand], validating it, mutating state, and emitting
  /// the resulting [MatchEvent]s.
  ///
  /// Throws a [StateError] if a validation rule is violated.
  Future<void> execute(MatchCommand command) async {
    switch (command) {
      case CreateMatchCommand():
        await _handleCreate(command);
      case JoinMatchCommand():
        _handleJoin(command);
      case LeaveMatchCommand():
        _handleLeave(command);
      case StartMatchCommand():
        _handleStartMatch(command);
      case StartRoundCommand():
        await _handleStartRound(command);
      case ChooseWordCommand():
        _handleChooseWord(command);
      case SubmitGuessCommand():
        _handleSubmitGuess(command);
      case SkipTurnCommand():
        _handleSkipTurn(command);
      case EndRoundCommand():
        _handleEndRound(command);
      case FinishMatchCommand():
        _handleFinishMatch(command);
      case CancelMatchCommand():
        _handleCancelMatch(command);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Snapshot
  // ───────────────────────────────────────────────────────────────────────────

  /// Returns an immutable snapshot of the current match state.
  MatchSnapshot? takeSnapshot() =>
      _match != null ? MatchSnapshot.from(_match!) : null;

  // ───────────────────────────────────────────────────────────────────────────
  // Private handlers
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handleCreate(CreateMatchCommand cmd) async {
    final configResult = validator.validateConfiguration(cmd.configuration);
    if (!configResult.isValid) {
      throw StateError('CreateMatch failed: ${configResult.reason}');
    }

    final id = MatchId.generate();
    final hostSlot = PlayerSlot(
      slotId: generateV4Uuid(),
      playerId: cmd.hostId,
      displayName: 'Host',
      role: PlayerRole.host,
    );

    _match = Match(
      id: id,
      hostId: cmd.hostId,
      configuration: cmd.configuration,
      players: [hostSlot],
      rounds: const [],
      state: const MatchCreatedState(),
      createdAt: DateTime.now(),
    );

    _turnManager = TurnManager(
      players: _match!.players,
      rules: rules.turnRules,
    );

    dispatcher.dispatch(
      MatchCreatedEvent(
        matchId: id,
        timestamp: DateTime.now(),
        hostId: cmd.hostId,
      ),
    );

    _transitionTo(const MatchWaitingState());
  }

  void _handleJoin(JoinMatchCommand cmd) {
    _requireMatch();
    final joinResult = validator.validatePlayerJoin(
      _match!.players,
      _match!.configuration,
    );
    if (!joinResult.isValid) {
      throw StateError('JoinMatch failed: ${joinResult.reason}');
    }

    final slot = PlayerSlot(
      slotId: generateV4Uuid(),
      playerId: cmd.playerId,
      displayName: cmd.displayName,
      role: PlayerRole.guesser,
      avatarId: cmd.avatarId,
    );

    _match = _match!.copyWith(
      players: [..._match!.players, slot],
    );
    _turnManager!.updatePlayers(_match!.players);

    dispatcher.dispatch(
      PlayerJoinedEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        playerId: cmd.playerId,
        displayName: cmd.displayName,
      ),
    );
  }

  void _handleLeave(LeaveMatchCommand cmd) {
    _requireMatch();
    final updated =
        _match!.players.map((p) {
          return p.playerId == cmd.playerId
              ? p.copyWith(isConnected: false)
              : p;
        }).toList();

    _match = _match!.copyWith(players: updated);
    _turnManager!.updatePlayers(updated);

    dispatcher.dispatch(
      PlayerLeftEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        playerId: cmd.playerId,
      ),
    );
  }

  void _handleStartMatch(StartMatchCommand cmd) {
    _requireMatch();
    final readyResult = validator.validateReadyToStart(
      _match!.players,
      _match!.configuration,
    );
    if (!readyResult.isValid) {
      throw StateError('StartMatch failed: ${readyResult.reason}');
    }
    _transitionTo(const MatchStartingState());
    dispatcher.dispatch(
      MatchStartedEvent(matchId: _match!.id, timestamp: DateTime.now()),
    );
  }

  Future<void> _handleStartRound(StartRoundCommand cmd) async {
    _requireMatch();
    final drawer = _turnManager!.advance();
    if (drawer == null) {
      throw StateError('StartRound failed: no eligible drawer');
    }

    final roundNumber = _match!.rounds.length + 1;
    final wordOptions = await wordSelector.selectWordsForRound(
      _match!.configuration,
    );

    final round = Round(
      id: RoundId.generate(),
      matchId: _match!.id,
      roundNumber: roundNumber,
      state: const RoundIdleState(),
      drawerSlotId: drawer.slotId,
      configuration: _match!.configuration.roundConfiguration,
      wordOptions: wordOptions,
    );

    // Update drawer role
    final updatedPlayers =
        _match!.players.map((p) {
          if (p.slotId == drawer.slotId) {
            return p.copyWith(role: PlayerRole.drawer);
          }
          if (p.role == PlayerRole.drawer) {
            return p.copyWith(role: PlayerRole.guesser);
          }
          return p;
        }).toList();

    _match = _match!.copyWith(
      rounds: [..._match!.rounds, round],
      players: updatedPlayers,
      currentRoundIndex: _match!.rounds.length,
    );

    _transitionTo(const WordSelectionState());

    dispatcher.dispatch(
      RoundStartedEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        roundNumber: roundNumber,
        drawerId: drawer.playerId,
      ),
    );
  }

  void _handleChooseWord(ChooseWordCommand cmd) {
    _requireMatch();
    final round = _match!.currentRound;
    if (round == null) throw StateError('No active round');

    final chosen = round.wordOptions.where((w) => w.id == cmd.wordId).firstOrNull;
    if (chosen == null) {
      throw StateError('ChooseWord failed: word ${cmd.wordId} not in options');
    }

    final turn = PlayerTurn(
      roundNumber: round.roundNumber,
      drawerId: cmd.drawerId,
      drawerDisplayName:
          _match!.playerByPlayerId(cmd.drawerId)?.displayName ?? cmd.drawerId,
      startedAt: DateTime.now(),
      wordsOffered: round.wordOptions.map((w) => w.id).toList(),
      wordChosenId: cmd.wordId,
    );

    final updatedRound = round.copyWith(
      word: chosen,
      state: const RoundActiveState(),
      playerTurn: turn,
      startedAt: DateTime.now(),
    );

    _match = _match!.copyWith(
      rounds: _replaceCurrent(updatedRound),
    );

    _transitionTo(const DrawingState());

    dispatcher.dispatch(
      WordChosenEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        roundNumber: round.roundNumber,
        wordId: cmd.wordId,
      ),
    );
  }

  void _handleSubmitGuess(SubmitGuessCommand cmd) {
    _requireMatch();
    final round = _match!.currentRound;
    if (round == null) throw StateError('No active round');
    if (round.word == null) throw StateError('No word chosen for round');

    final isCorrect = rules.wordRules.isCorrectGuess(
      cmd.guessText,
      round.word!.text,
    );
    final result = isCorrect ? GuessResult.correct : GuessResult.incorrect;
    final now = DateTime.now();
    final guessTimeMs =
        round.startedAt != null
            ? now.difference(round.startedAt!).inMilliseconds
            : 0;

    final guess = Guess(
      playerId: cmd.playerId,
      text: cmd.guessText,
      submittedAt: now,
      result: result,
      guessTimeMs: guessTimeMs,
    );

    final updatedRound = round.copyWith(
      guesses: [...round.guesses, guess],
    );
    _match = _match!.copyWith(rounds: _replaceCurrent(updatedRound));

    dispatcher.dispatch(
      GuessSubmittedEvent(
        matchId: _match!.id,
        timestamp: now,
        playerId: cmd.playerId,
        guessText: cmd.guessText,
      ),
    );

    if (isCorrect) {
      final isFirst =
          !round.guesses.any((g) => g.result == GuessResult.correct);
      final scoreResult = scoring.scoreCorrectGuess(
        playerId: cmd.playerId,
        roundId: round.id,
        guessTimeMs: guessTimeMs,
        config: _match!.configuration,
        isFirstGuesser: isFirst,
        difficulty: round.word!.difficulty,
      );

      dispatcher.dispatch(
        CorrectGuessEvent(
          matchId: _match!.id,
          timestamp: now,
          playerId: cmd.playerId,
          guessTimeMs: guessTimeMs,
          pointsAwarded: scoreResult.points,
        ),
      );
    }
  }

  void _handleSkipTurn(SkipTurnCommand cmd) {
    _requireMatch();
    dispatcher.dispatch(
      PlayerSkippedEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        playerId: cmd.drawerId,
      ),
    );
    execute(EndRoundCommand(matchId: cmd.matchId, reason: 'skipped'));
  }

  void _handleEndRound(EndRoundCommand cmd) {
    _requireMatch();
    final round = _match!.currentRound;
    if (round == null) return;

    // Tally scores
    final correctGuesses =
        round.guesses.where((g) => g.result.awardsPoints).toList();
    final drawerScore = scoring.scoreDrawer(
      drawerId: round.drawerSlotId,
      roundId: round.id,
      correctGuessCount: correctGuesses.length,
      difficulty: round.word?.difficulty ?? _match!.configuration.difficulty,
    );

    final allScores = [...round.scores];
    if (drawerScore != null) allScores.add(drawerScore.toScore());

    // Update player totals
    final updatedPlayers = _match!.players.map((p) {
      final earned = allScores
          .where((s) => s.playerId == p.slotId || s.playerId == p.playerId)
          .fold(0, (sum, s) => sum + s.points);
      return earned > 0 ? p.copyWith(totalScore: p.totalScore + earned) : p;
    }).toList();

    // Record turn history
    final turn = round.playerTurn?.copyWith(
      endedAt: DateTime.now(),
      completed: true,
    );
    if (turn != null) _turnManager!.recordTurn(turn);

    final updatedRound = round.copyWith(
      state: const RoundFinishedRoundState(),
      scores: allScores,
      playerTurn: turn,
      finishedAt: DateTime.now(),
    );

    _match = _match!.copyWith(
      rounds: _replaceCurrent(updatedRound),
      players: updatedPlayers,
    );

    _transitionTo(const RoundFinishedState());

    dispatcher.dispatch(
      RoundEndedEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        roundNumber: round.roundNumber,
      ),
    );

    if (round.word != null) {
      dispatcher.dispatch(
        WordRevealedEvent(
          matchId: _match!.id,
          timestamp: DateTime.now(),
          roundNumber: round.roundNumber,
          wordText: round.word!.text,
        ),
      );
    }
  }

  void _handleFinishMatch(FinishMatchCommand cmd) {
    _requireMatch();
    _transitionTo(const ScoreboardState());

    final scores = <String, int>{};
    for (final player in _match!.players) {
      scores[player.playerId] = player.totalScore;
    }

    final winnerId = rules.victoryRules.determineWinner(scores);
    final winner = winnerId != null
        ? _match!.playerByPlayerId(winnerId)
        : null;

    final result = MatchResult(
      winnerId: winnerId ?? '',
      winnerDisplayName: winner?.displayName ?? 'Draw',
      finalScores: scores,
      totalRounds: _match!.rounds.length,
      startedAt: _match!.startedAt ?? _match!.createdAt,
      endedAt: DateTime.now(),
    );

    _match = _match!.copyWith(result: result);
    _transitionTo(const MatchFinishedState());

    dispatcher.dispatch(
      MatchEndedEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        winnerId: winnerId ?? '',
      ),
    );
  }

  void _handleCancelMatch(CancelMatchCommand cmd) {
    _requireMatch();
    _transitionTo(const MatchCancelledState());
    dispatcher.dispatch(
      MatchCancelledEvent(
        matchId: _match!.id,
        timestamp: DateTime.now(),
        reason: cmd.reason,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  void _requireMatch() {
    if (_match == null) throw StateError('No match loaded');
  }

  void _transitionTo(MatchState next) {
    final result = validator.validateTransition(_match!.state, next);
    if (!result.isValid) {
      throw StateError('Invalid transition: ${result.reason}');
    }
    _match = _match!.copyWith(state: next);
  }

  List<Round> _replaceCurrent(Round updated) {
    final rounds = List<Round>.from(_match!.rounds);
    rounds[_match!.currentRoundIndex] = updated;
    return rounds;
  }
}

extension _ListExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
