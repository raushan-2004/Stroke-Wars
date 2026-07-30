import 'package:stroke_wars/core/utils/uuid.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/match_state_machine.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/domain/models/match_snapshot.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/sequence_generator.dart';
import 'package:stroke_wars/features/match/application/turn_manager.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/application/timers/match_clock.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/command_context.dart';
import 'package:stroke_wars/features/match/domain/models/guess.dart';
import 'package:stroke_wars/features/match/domain/models/guess_result.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_context.dart';
import 'package:stroke_wars/features/match/domain/models/match_failure.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_result.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/player_turn.dart';
import 'package:stroke_wars/features/match/domain/models/result.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/match/domain/models/score.dart';
import 'package:stroke_wars/features/match/domain/models/state_transition.dart';

/// Outcome of a gameplay dry-run calculation.
class DryRunOutcome {
  const DryRunOutcome({
    required this.toState,
    required this.events,
    required this.mutatedMatch,
  });

  /// The next MatchState.
  final MatchState toState;

  /// The list of generated MatchEvents.
  final List<MatchEvent> events;

  /// The updated Match aggregate.
  final Match mutatedMatch;
}

/// Plain Dart orchestrator for the match domain.
///
/// Under Stage 5B, all state mutations happen by applying a [StateTransition]
/// produced by the [MatchStateMachine].
class MatchController {
  MatchController({
    required this.dispatcher,
    required this.validator,
    required this.rules,
    required this.scoring,
    required this.wordSelector,
    required this.clock,
    required this.sequenceGenerator,
  }) : matchClock = MatchClock();

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

  /// Clock provider.
  final ClockProvider clock;

  /// Sequence generator.
  final SequenceGenerator sequenceGenerator;

  /// Unified timer clock.
  final MatchClock matchClock;

  Match? _match;
  TurnManager? _turnManager;

  // ───────────────────────────────────────────────────────────────────────────
  // Queries
  // ───────────────────────────────────────────────────────────────────────────

  /// The current match, or null if none is active.
  Match? get match => _match;

  /// Sets the match instance. Only used for testing.
  set match(Match? value) {
    _match = value;
    if (value != null) {
      _turnManager = TurnManager(players: value.players, rules: rules.turnRules);
      for (final turn in value.turnHistory) {
        _turnManager!.recordTurn(turn);
      }
    }
  }

  /// Current [MatchContext], or null if no match is loaded.
  MatchContext? get context =>
      _match != null ? MatchContext.from(_match!) : null;

  /// Returns an immutable snapshot of the current match state.
  MatchSnapshot? takeSnapshot() =>
      _match != null ? MatchSnapshot.from(_match!) : null;

  /// True if a match is currently loaded and active.
  bool get hasActiveMatch =>
      _match != null && !_match!.state.isTerminal;

  // ───────────────────────────────────────────────────────────────────────────
  // State Mutation (Transition Application)
  // ───────────────────────────────────────────────────────────────────────────

  /// Applies a [StateTransition] to update the [MatchState] and dispatches
  /// the associated events to the bus.
  void applyTransition(StateTransition transition, Match mutatedMatch) {
    // 1. Update sequence generator to the latest assigned sequence number
    if (transition.generatedEvents.isNotEmpty) {
      sequenceGenerator.current = transition.generatedEvents.last.sequenceNumber;
    }

    // 2. Tally final turn / score additions in command histories
    final appendedCommands = [...mutatedMatch.commandHistory, transition.triggerCommand];
    final appendedTransitions = [...mutatedMatch.transitionHistory, transition];
    final appendedEvents = [...mutatedMatch.eventHistory, ...transition.generatedEvents];

    // 3. Save mutated state with added histories
    _match = mutatedMatch.copyWith(
      state: transition.toState,
      commandHistory: appendedCommands,
      eventHistory: appendedEvents,
      transitionHistory: appendedTransitions,
    );

    // 4. Update TurnManager list and history
    if (_turnManager == null) {
      _turnManager = TurnManager(players: _match!.players, rules: rules.turnRules);
    } else {
      _turnManager!.updatePlayers(_match!.players);
    }
    _turnManager!.currentIndex = _match!.currentRoundIndex;
    for (final turn in transition.generatedEvents.whereType<RoundEndedEvent>()) {
      final round = _match!.rounds.firstWhere((r) => r.roundNumber == turn.roundNumber);
      if (round.playerTurn != null) {
        _turnManager!.recordTurn(round.playerTurn!);
      }
    }

    // 5. Dispatch all events to the dispatcher
    dispatcher.dispatchAll(transition.generatedEvents);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Dry-Run Logic (Pure Computations)
  // ───────────────────────────────────────────────────────────────────────────

  /// Dry-runs a command against a [CommandContext] to produce next state and events.
  ///
  /// This method is pure and does not modify the current state of [MatchController].
  Future<Result<DryRunOutcome>> dryRun(CommandContext context) async {
    final cmd = context.command;
    final match = context.currentMatch;
    var seq = context.sequenceNumber;

    if (cmd is CreateMatchCommand) {
      final hostSlot = PlayerSlot(
        slotId: generateV4Uuid(),
        playerId: cmd.hostId,
        displayName: 'Host',
        role: PlayerRole.host,
      );

      final newMatch = Match(
        id: MatchId.generate(),
        hostId: cmd.hostId,
        configuration: cmd.configuration,
        players: [hostSlot],
        rounds: const [],
        state: const MatchCreatedState(),
        createdAt: clock.now,
      );

      final event = MatchCreatedEvent(
        matchId: newMatch.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        originPlayer: cmd.hostId,
        hostId: cmd.hostId,
      );

      return Success(DryRunOutcome(
        toState: const MatchWaitingState(),
        events: [event],
        mutatedMatch: newMatch,
      ));
    }

    if (cmd is JoinMatchCommand) {
      final slot = PlayerSlot(
        slotId: generateV4Uuid(),
        playerId: cmd.playerId,
        displayName: cmd.displayName,
        role: PlayerRole.guesser,
        avatarId: cmd.avatarId,
      );

      final updatedMatch = match.copyWith(
        players: [...match.players, slot],
      );

      final event = PlayerJoinedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        originPlayer: cmd.playerId,
        playerId: cmd.playerId,
        displayName: cmd.displayName,
      );

      return Success(DryRunOutcome(
        toState: const MatchWaitingState(),
        events: [event],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is LeaveMatchCommand) {
      final updated = match.players.map((p) {
        return p.playerId == cmd.playerId
            ? p.copyWith(isConnected: false)
            : p;
      }).toList();

      final updatedMatch = match.copyWith(players: updated);
      final event = PlayerLeftEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        originPlayer: cmd.playerId,
        playerId: cmd.playerId,
      );

      return Success(DryRunOutcome(
        toState: match.state,
        events: [event],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is ReadyPlayerCommand) {
      final updated = match.players.map((p) {
        return p.playerId == cmd.playerId
            ? p.copyWith(isReady: cmd.isReady)
            : p;
      }).toList();

      final updatedMatch = match.copyWith(players: updated);
      final event = PlayerReadinessEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        originPlayer: cmd.playerId,
        playerId: cmd.playerId,
        isReady: cmd.isReady,
      );

      return Success(DryRunOutcome(
        toState: const MatchWaitingState(),
        events: [event],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is StartMatchCommand) {
      final updatedMatch = match.copyWith(startedAt: clock.now);
      final event = MatchStartedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        originPlayer: cmd.hostId,
      );

      return Success(DryRunOutcome(
        toState: const MatchStartingState(),
        events: [event],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is StartRoundCommand) {
      final tempTurnManager = TurnManager(players: match.players, rules: rules.turnRules);
      for (final turn in match.turnHistory) {
        tempTurnManager.recordTurn(turn);
      }
      tempTurnManager.currentIndex = match.currentRoundIndex;

      final drawer = tempTurnManager.advance();
      if (drawer == null) {
        return const Failure(PlayerNotFoundFailure('No eligible drawer found.'));
      }

      final roundNumber = match.rounds.length + 1;
      final wordOptions = await wordSelector.selectWordsForRound(match.configuration);

      final round = Round(
        id: RoundId.generate(),
        matchId: match.id,
        roundNumber: roundNumber,
        state: const RoundIdleState(),
        drawerSlotId: drawer.slotId,
        configuration: match.configuration.roundConfiguration,
        wordOptions: wordOptions,
      );

      final updatedPlayers = match.players.map((p) {
        if (p.slotId == drawer.slotId) {
          return p.copyWith(role: PlayerRole.drawer);
        }
        if (p.role == PlayerRole.drawer) {
          return p.copyWith(role: PlayerRole.guesser);
        }
        return p;
      }).toList();

      final updatedMatch = match.copyWith(
        rounds: [...match.rounds, round],
        players: updatedPlayers,
        currentRoundIndex: match.rounds.length,
      );

      final event = RoundStartedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        roundId: round.id.value,
        roundNumber: roundNumber,
        drawerId: drawer.playerId,
      );

      return Success(DryRunOutcome(
        toState: const WordSelectionState(),
        events: [event],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is ChooseWordCommand) {
      final round = context.currentRound;
      if (round == null) {
        return const Failure(InvalidTransitionFailure('No active round.'));
      }

      final chosen = round.wordOptions.firstWhere((w) => w.id == cmd.wordId);

      final turn = PlayerTurn(
        roundNumber: round.roundNumber,
        drawerId: cmd.drawerId,
        drawerDisplayName:
            match.playerByPlayerId(cmd.drawerId)?.displayName ?? cmd.drawerId,
        startedAt: clock.now,
        wordsOffered: round.wordOptions.map((w) => w.id).toList(),
        wordChosenId: cmd.wordId,
      );

      final updatedRound = round.copyWith(
        word: chosen,
        state: const RoundActiveState(),
        playerTurn: turn,
        startedAt: clock.now,
      );

      final updatedMatch = match.copyWith(
        rounds: _replaceCurrentRound(match, updatedRound),
      );

      final event = WordChosenEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        roundId: round.id.value,
        roundNumber: round.roundNumber,
        wordId: cmd.wordId,
      );

      return Success(DryRunOutcome(
        toState: const DrawingState(),
        events: [event],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is SubmitGuessCommand) {
      final round = context.currentRound;
      if (round == null) {
        return const Failure(InvalidTransitionFailure('No active round.'));
      }

      final isCorrect = rules.wordRules.isCorrectGuess(cmd.guessText, round.word!.text);
      final result = isCorrect ? GuessResult.correct : GuessResult.incorrect;
      final guessTimeMs = round.startedAt != null
          ? clock.now.difference(round.startedAt!).inMilliseconds
          : 0;

      final guess = Guess(
        playerId: cmd.playerId,
        text: cmd.guessText,
        submittedAt: clock.now,
        result: result,
        guessTimeMs: guessTimeMs,
      );

      final newScores = List<Score>.from(round.scores);
      final newScoreHistory = List<Score>.from(match.scoreHistory);
      var pointsAwarded = 0;

      if (isCorrect) {
        final isFirst = !round.guesses.any((g) => g.result == GuessResult.correct);
        final scoreResult = scoring.scoreCorrectGuess(
          playerId: cmd.playerId,
          roundId: round.id,
          guessTimeMs: guessTimeMs,
          config: match.configuration,
          isFirstGuesser: isFirst,
          difficulty: round.word!.difficulty,
        );
        final score = scoreResult.toScore();
        newScores.add(score);
        newScoreHistory.add(score);
        pointsAwarded = scoreResult.points;
      }

      final generatedEvents = <MatchEvent>[];
      generatedEvents.add(GuessSubmittedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        roundId: round.id.value,
        originPlayer: cmd.playerId,
        playerId: cmd.playerId,
        guessText: cmd.guessText,
      ));

      if (isCorrect) {
        generatedEvents.add(CorrectGuessEvent(
          matchId: match.id,
          timestamp: clock.now,
          sequenceNumber: seq++,
          roundId: round.id.value,
          originPlayer: cmd.playerId,
          playerId: cmd.playerId,
          guessTimeMs: guessTimeMs,
          pointsAwarded: pointsAwarded,
        ));
      }

      var updatedRound = round.copyWith(
        guesses: [...round.guesses, guess],
        scores: newScores,
      );

      final updatedMatch = match.copyWith(
        rounds: _replaceCurrentRound(match, updatedRound),
        scoreHistory: newScoreHistory,
      );
      return Success(DryRunOutcome(
        toState: const GuessingState(),
        events: generatedEvents,
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is SkipTurnCommand) {
      final round = context.currentRound;
      if (round == null) {
        return const Failure(InvalidTransitionFailure('No active round.'));
      }

      final turn = round.playerTurn?.copyWith(
        endedAt: clock.now,
        completed: false,
      );

      final updatedRound = round.copyWith(
        state: const RoundFinishedRoundState(),
        playerTurn: turn,
        finishedAt: clock.now,
      );

      final updatedMatch = match.copyWith(
        rounds: _replaceCurrentRound(match, updatedRound),
        turnHistory: turn != null ? [...match.turnHistory, turn] : match.turnHistory,
      );

      final event1 = PlayerSkippedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        roundId: round.id.value,
        originPlayer: cmd.drawerId,
        playerId: cmd.drawerId,
      );

      final event2 = RoundEndedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        roundId: round.id.value,
        roundNumber: round.roundNumber,
      );

      return Success(DryRunOutcome(
        toState: const RoundFinishedState(),
        events: [event1, event2],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is EndRoundCommand) {
      final round = context.currentRound;
      if (round == null) {
        return const Failure(InvalidTransitionFailure('No active round.'));
      }

      final correctGuesses = round.guesses.where((g) => g.result.awardsPoints).toList();
      final drawerScore = scoring.scoreDrawer(
        drawerId: round.drawerSlotId,
        roundId: round.id,
        correctGuessCount: correctGuesses.length,
        difficulty: round.word?.difficulty ?? match.configuration.difficulty,
      );

      final allScores = [...round.scores];
      final newScoreHistory = List<Score>.from(match.scoreHistory);
      if (drawerScore != null) {
        final score = drawerScore.toScore();
        allScores.add(score);
        newScoreHistory.add(score);
      }

      final updatedPlayers = match.players.map((p) {
        final earned = allScores
            .where((s) => s.playerId == p.slotId || s.playerId == p.playerId)
            .fold(0, (sum, s) => sum + s.points);
        return earned > 0 ? p.copyWith(totalScore: p.totalScore + earned) : p;
      }).toList();

      final turn = round.playerTurn?.copyWith(
        endedAt: clock.now,
        completed: true,
      );

      final updatedRound = round.copyWith(
        state: const RoundFinishedRoundState(),
        scores: allScores,
        playerTurn: turn,
        finishedAt: clock.now,
      );

      final updatedMatch = match.copyWith(
        rounds: _replaceCurrentRound(match, updatedRound),
        players: updatedPlayers,
        scoreHistory: newScoreHistory,
        turnHistory: turn != null ? [...match.turnHistory, turn] : match.turnHistory,
      );

      final event1 = RoundEndedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        roundId: round.id.value,
        roundNumber: round.roundNumber,
      );

      final events = <MatchEvent>[event1];
      if (round.word != null) {
        events.add(WordRevealedEvent(
          matchId: match.id,
          timestamp: clock.now,
          sequenceNumber: seq++,
          roundId: round.id.value,
          roundNumber: round.roundNumber,
          wordText: round.word!.text,
        ));
      }

      return Success(DryRunOutcome(
        toState: const RoundFinishedState(),
        events: events,
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is FinishMatchCommand) {
      final scores = <String, int>{};
      for (final player in match.players) {
        scores[player.playerId] = player.totalScore;
      }

      final winnerId = rules.victoryRules.determineWinner(scores);
      final winner = winnerId != null ? match.playerByPlayerId(winnerId) : null;

      final result = MatchResult(
        winnerId: winnerId ?? '',
        winnerDisplayName: winner?.displayName ?? 'Draw',
        finalScores: scores,
        totalRounds: match.rounds.length,
        startedAt: match.startedAt ?? match.createdAt,
        endedAt: clock.now,
      );

      final updatedMatch = match.copyWith(result: result);
      final event = MatchEndedEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        winnerId: winnerId ?? '',
      );

      return Success(DryRunOutcome(
        toState: const MatchFinishedState(),
        events: [event],
        mutatedMatch: updatedMatch,
      ));
    }

    if (cmd is CancelMatchCommand) {
      final event = MatchCancelledEvent(
        matchId: match.id,
        timestamp: clock.now,
        sequenceNumber: seq++,
        reason: cmd.reason,
      );

      return Success(DryRunOutcome(
        toState: const MatchCancelledState(),
        events: [event],
        mutatedMatch: match,
      ));
    }

    return const Failure(UnexpectedCommandFailure('Unknown', 'Unknown'));
  }

  List<Round> _replaceCurrentRound(Match match, Round updated) {
    final list = List<Round>.from(match.rounds);
    list[match.currentRoundIndex] = updated;
    return list;
  }

  /// Executes a command through the command processor.
  ///
  /// Exposes a direct execution API to maintain compatibility with older tests.
  Future<void> execute(MatchCommand command) async {
    final stateMachine = MatchStateMachine(validator: validator);
    final processor = MatchCommandProcessor(
      controller: this,
      stateMachine: stateMachine,
      clock: clock,
    );
    final result = await processor.process(command);
    if (result is Failure) {
      throw StateError(result.errorOrThrow.toString());
    }
  }
}
