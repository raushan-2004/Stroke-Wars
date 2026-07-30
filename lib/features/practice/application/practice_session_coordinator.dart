import 'dart:async';
import 'dart:math';

import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/sequence_generator.dart';
import 'package:stroke_wars/features/match/application/timers/match_clock.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/application/match_state_machine.dart';
import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/domain/models/command_result.dart';
import 'package:stroke_wars/features/match/domain/models/result.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_failure.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/match/domain/models/timer_state.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/practice/application/practice_bot_engine.dart';
import 'package:stroke_wars/features/practice/application/practice_replay_recorder.dart';
import 'package:stroke_wars/features/practice/application/practice_statistics_collector.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_configuration.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_session.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_statistics.dart';

/// Custom TurnRules that locks the drawer slot to the human player for all rounds.
class PracticeTurnRules extends TurnRules {
  const PracticeTurnRules({required this.humanPlayerId});
  final String humanPlayerId;

  @override
  bool isEligibleDrawer(PlayerSlot slot) => slot.playerId == humanPlayerId;
}

/// Orchestrates CanvasController, MatchController, Bot engine, and stats collection for practice.
class PracticeSessionCoordinator {
  PracticeSessionCoordinator({
    required this.canvasController,
    required this.drawingBus,
    required this.humanPlayerId,
    required this.humanDisplayName,
    required this.configuration,
    required this.onSessionUpdated,
    required this.onAutosaveTriggered,
    ClockProvider? clock,
  })  : clock = clock ?? const SystemClock(),
        replayRecorder = PracticeReplayRecorder(),
        statsCollector = const PracticeStatisticsCollector() {
    _initializeSession();
  }

  final CanvasController canvasController;
  final DrawingEventBus drawingBus;
  final String humanPlayerId;
  final String humanDisplayName;
  final PracticeConfiguration configuration;
  final void Function(PracticeSession) onSessionUpdated;
  final void Function(PracticeSession) onAutosaveTriggered;
  final ClockProvider clock;

  final PracticeReplayRecorder replayRecorder;
  final PracticeStatisticsCollector statsCollector;

  late final MatchController _matchController;
  late final MatchCommandProcessor _commandProcessor;
  late final MatchEventBus _matchEventBus;

  StreamSubscription<MatchEvent>? _matchSub;
  StreamSubscription<MatchClockState>? _clockSub;
  StreamSubscription<dynamic>? _drawingSub;

  late PracticeSession _session;
  PracticeBotEngine? _botEngine;
  bool _isPaused = false;
  bool _disposed = false;

  /// Returns the current active session state.
  PracticeSession get session => _session;

  void _initializeSession() {
    _matchEventBus = MatchEventBus();
    final dispatcher = MatchEventDispatcher(bus: _matchEventBus);
    final rules = RuleEngine(
      turnRules: PracticeTurnRules(humanPlayerId: humanPlayerId),
      scoreRules: const ScoreRules(),
      wordRules: const WordRules(),
      victoryRules: const VictoryRules(),
      configurationRules: const ConfigurationRules(),
    );

    _matchController = MatchController(
      dispatcher: dispatcher,
      validator: MatchValidator(),
      rules: rules,
      scoring: const ScoringEngine(),
      wordSelector: WordSelector(
        repository: const DefaultWordList(),
        random: DefaultRandomProvider(),
      ),
      clock: clock,
      sequenceGenerator: SequenceGenerator(),
    );

    _commandProcessor = MatchCommandProcessor(
      controller: _matchController,
      stateMachine: MatchStateMachine(validator: MatchValidator()),
      clock: clock,
    );

    _session = PracticeSession(
      currentMatch: Match(
        id: const MatchId('practice-match'),
        hostId: humanPlayerId,
        state: const MatchCreatedState(),
        players: const [],
        rounds: const [],
        createdAt: clock.now,
        configuration: MatchConfiguration(
          minPlayers: 2,
          maxPlayers: configuration.botCount + 1,
          totalRounds: configuration.rounds,
          drawTimeSecs: configuration.drawTimeSecs,
          scoreboardTimeSecs: configuration.scoreboardTimeSecs,
        ),
      ),
      canvasState: canvasController.state,
      timerState: const TimerState(durationSecs: 0, elapsedSecs: 0, isRunning: false),
      score: 0,
      practiceStatistics: const PracticeStatistics(),
      configuration: configuration,
    );

    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _matchSub = _matchEventBus.stream.listen((event) {
      if (_disposed) return;
      replayRecorder.recordMatchEvent(event, clock.now);
      _handleMatchEvent(event);
    });

    _clockSub = _matchController.matchClock.stream.listen((tick) {
      if (_disposed || _isPaused) return;

      final isDrawing = tick.type == MatchClockType.round;
      var updatedStats = statsCollector.processTimeTick(
        _session.practiceStatistics,
        1.0,
        isDrawing,
      );

      // Bot simulation tick
      if (isDrawing && tick.timerState.isRunning && !tick.timerState.isPaused) {
        final engine = _botEngine;
        if (engine != null) {
          final commands = engine.tick(tick.timerState.elapsedSecs, _session.currentMatch.id);
          for (final cmd in commands) {
            _commandProcessor.process(cmd).catchError((_) => Failure<CommandResult>(InvalidTransitionFailure('Bot command error')));
          }
        }
      }

      _session = _session.copyWith(
        timerState: tick.timerState,
        practiceStatistics: updatedStats,
      );
      onSessionUpdated(_session);
    });

    _drawingSub = drawingBus.stream.listen((event) {
      if (_disposed || _isPaused) return;

      // Ensure canvas is active and read-only is false
      if (_session.currentMatch.state is! DrawingState &&
          _session.currentMatch.state is! GuessingState) {
        return;
      }

      replayRecorder.recordDrawingEvent(event, clock.now);
      final updatedStats = statsCollector.processDrawingEvent(
        _session.practiceStatistics,
        event,
      );

      _session = _session.copyWith(
        practiceStatistics: updatedStats,
        canvasState: canvasController.state,
      );
      onSessionUpdated(_session);
    });
  }

  Future<void> start() async {
    try {
      final config = _session.currentMatch.configuration;
      final matchId = _session.currentMatch.id;

      // 1. Create Match
      await _commandProcessor.process(CreateMatchCommand(
        hostId: humanPlayerId,
        configuration: config,
      ));

      // 2. Add Bots
      for (var i = 1; i <= configuration.botCount; i++) {
        await _commandProcessor.process(JoinMatchCommand(
          matchId: matchId,
          playerId: 'bot-$i',
          displayName: 'Bot ${['Alice', 'Bob', 'Charlie'][i - 1]}',
        ));
      }

      // 3. Ready human and bots
      await _commandProcessor.process(ReadyPlayerCommand(
        matchId: matchId,
        playerId: humanPlayerId,
        isReady: true,
      ));

      for (var i = 1; i <= configuration.botCount; i++) {
        await _commandProcessor.process(ReadyPlayerCommand(
          matchId: matchId,
          playerId: 'bot-$i',
          isReady: true,
        ));
      }

      // 4. Start Match
      await _commandProcessor.process(StartMatchCommand(
        matchId: matchId,
        hostId: humanPlayerId,
      ));

      // 5. Start first round selection
      await _commandProcessor.process(StartRoundCommand(matchId: matchId));
    } catch (_) {
      // Safe recovery
      _isPaused = false;
    }
  }

  Future<void> chooseWord(Word word) async {
    try {
      final matchId = _session.currentMatch.id;
      await _commandProcessor.process(ChooseWordCommand(
        matchId: matchId,
        drawerId: humanPlayerId,
        wordId: word.id,
      ));
    } catch (_) {
      // Recovery
    }
  }

  Future<void> endRound() async {
    try {
      _matchController.matchClock.stop();
      final matchId = _session.currentMatch.id;
      await _commandProcessor.process(EndRoundCommand(matchId: matchId));
    } catch (_) {
      // Recovery
    }
  }

  Future<void> advanceNextRound() async {
    try {
      final match = _session.currentMatch;
      final completedRounds = match.rounds.where((r) => r.state is RoundFinishedRoundState).length;
      if (completedRounds >= match.configuration.totalRounds) {
        await _commandProcessor.process(FinishMatchCommand(matchId: match.id));
      } else {
        await _commandProcessor.process(StartRoundCommand(matchId: match.id));
      }
    } catch (_) {
      // Recovery
    }
  }

  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    _matchController.matchClock.pause();
    _session = _session.copyWith(
      practiceStatistics: statsCollector.processPause(_session.practiceStatistics),
      timerState: _matchController.matchClock.current.timerState,
    );
    onSessionUpdated(_session);
    onAutosaveTriggered(_session);
  }

  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    _matchController.matchClock.resume();
    _session = _session.copyWith(
      timerState: _matchController.matchClock.current.timerState,
    );
    onSessionUpdated(_session);
  }

  void restart() {
    _matchController.matchClock.stop();
    replayRecorder.clear();
    canvasController.resetHistory();
    _initializeSession();
    start();
  }

  void quit() {
    _matchController.matchClock.stop();
    onAutosaveTriggered(_session);
  }

  void _handleMatchEvent(MatchEvent event) {
    final prevMatch = _session.currentMatch;
    final nextMatch = _matchController.match ?? prevMatch;

    // Log state transitions in the replay recorder
    replayRecorder.recordRoundTransition(
      prevMatch.state.label,
      nextMatch.state.label,
      clock.now,
    );

    _session = _session.copyWith(
      currentMatch: nextMatch,
      currentRound: () => nextMatch.currentRound,
      currentWord: () => nextMatch.currentRound?.word,
      score: nextMatch.playerByPlayerId(humanPlayerId)?.totalScore ?? 0,
      canvasState: canvasController.state,
    );

    if (event is RoundStartedEvent) {
      try {
        canvasController.resetHistory();
      } catch (_) {}
      
      // Determine bots
      final botIds = nextMatch.players
          .where((p) => p.playerId != humanPlayerId)
          .map((p) => p.playerId)
          .toList();

      // Start Bot Guesser simulation
      final chosenWord = nextMatch.currentRound?.word?.text ?? 'target';
      final incorrectWords = DefaultWordList.words
          .where((w) => w.text != chosenWord)
          .map((w) => w.text)
          .toList();

      _botEngine = PracticeBotEngine(
        bots: botIds,
        targetWord: chosenWord,
        incorrectWordPool: incorrectWords,
      );
    } else if (event is RoundEndedEvent) {
      // Disallow drawing, save statistics
      final duration = nextMatch.currentRound?.playerTurn?.durationMs ?? 0;
      final updatedStats = statsCollector.processRoundCompletion(
        _session.practiceStatistics,
        (duration / 1000).round(),
      );

      _session = _session.copyWith(
        practiceStatistics: updatedStats,
        replayMetadata: replayRecorder.serialize(),
      );

      onAutosaveTriggered(_session);

      // Start scoreboard intermission
      _matchController.matchClock.startScoreboard(
        nextMatch.configuration.scoreboardTimeSecs,
        onComplete: () {
          advanceNextRound();
        },
      );
    } else if (event is MatchEndedEvent) {
      onAutosaveTriggered(_session);
    } else if (event is TimerExpiredEvent) {
      endRound();
    }

    onSessionUpdated(_session);
  }

  /// Restores session state from a loaded [PracticeSession] snapshot.
  void restoreSession(PracticeSession saved) {
    _session = saved;
    // Restore match controller state
    _matchController.match = saved.currentMatch;
    
    // Restore bots
    final chosenWord = saved.currentWord?.text ?? 'target';
    final incorrectWords = DefaultWordList.words
        .where((w) => w.text != chosenWord)
        .map((w) => w.text)
        .toList();

    final botIds = saved.currentMatch.players
        .where((p) => p.playerId != humanPlayerId)
        .map((p) => p.playerId)
        .toList();

    _botEngine = PracticeBotEngine(
      bots: botIds,
      targetWord: chosenWord,
      incorrectWordPool: incorrectWords,
    );

    onSessionUpdated(_session);
  }

  void dispose() {
    _disposed = true;
    _matchSub?.cancel();
    _clockSub?.cancel();
    _drawingSub?.cancel();
    _matchController.matchClock.dispose();
    _matchEventBus.dispose();
  }
}
