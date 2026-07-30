import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/match_state_machine.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/sequence_generator.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/application/timers/match_clock.dart';
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_failure.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/result.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';

void main() {
  group('Match State Machine & Gameplay Flow (MSMGF) Tests', () {
    late MatchEventBus bus;
    late MatchEventDispatcher dispatcher;
    late MatchValidator validator;
    late RuleEngine rules;
    late ScoringEngine scoring;
    late DefaultWordList wordListRepo;
    late WordSelector wordSelector;
    late TestClock clock;
    late SequenceGenerator sequenceGenerator;
    late MatchController controller;
    late MatchStateMachine stateMachine;
    late MatchCommandProcessor processor;

    setUp(() {
      bus = MatchEventBus();
      dispatcher = MatchEventDispatcher(bus: bus);
      validator = const MatchValidator();
      rules = const RuleEngine();
      scoring = const ScoringEngine();
      wordListRepo = const DefaultWordList();
      wordSelector = WordSelector(
        repository: wordListRepo,
        random: SeededRandomProvider(101),
      );
      clock = TestClock(DateTime(2026, 7, 29, 12, 0, 0));
      sequenceGenerator = SequenceGenerator();
      controller = MatchController(
        dispatcher: dispatcher,
        validator: validator,
        rules: rules,
        scoring: scoring,
        wordSelector: wordSelector,
        clock: clock,
        sequenceGenerator: sequenceGenerator,
      );
      stateMachine = MatchStateMachine(validator: validator);
      processor = MatchCommandProcessor(
        controller: controller,
        stateMachine: stateMachine,
        clock: clock,
      );
    });

    tearDown(() {
      bus.dispose();
      controller.matchClock.dispose();
    });

    test('1. ClockProvider & SequenceGenerator Determinism', () {
      expect(clock.now, DateTime(2026, 7, 29, 12, 0, 0));
      clock.advance(const Duration(minutes: 5));
      expect(clock.now, DateTime(2026, 7, 29, 12, 5, 0));

      expect(sequenceGenerator.current, 0);
      expect(sequenceGenerator.next(), 1);
      expect(sequenceGenerator.next(), 2);
      expect(sequenceGenerator.current, 2);
      sequenceGenerator.reset();
      expect(sequenceGenerator.current, 0);
    });

    test('2. Command Context Creation & Processing Flow', () async {
      final config = MatchConfiguration(
        minPlayers: 2,
        maxPlayers: 4,
        allowedCategories: const [WordCategory.animals],
      );

      final result = await processor.process(
        CreateMatchCommand(hostId: 'host-1', configuration: config),
      );

      expect(result.isSuccess, true);
      final outcome = result.valueOrThrow;
      expect(outcome.resultingState, isA<MatchWaitingState>());
      expect(outcome.generatedEvents.length, 1);
      expect(outcome.generatedEvents.first, isA<MatchCreatedEvent>());
      expect(outcome.stateTransition.fromState, isA<MatchCreatedState>());
      expect(outcome.stateTransition.toState, isA<MatchWaitingState>());
      expect(controller.match!.eventHistory.length, 1);
      expect(controller.match!.commandHistory.length, 1);
      expect(controller.match!.transitionHistory.length, 1);
    });

    test('3. Duplicate Command Rejection', () async {
      final config = MatchConfiguration(
        minPlayers: 2,
        maxPlayers: 4,
        allowedCategories: const [WordCategory.animals],
      );

      await processor.process(
        CreateMatchCommand(hostId: 'host-1', configuration: config),
      );
      await processor.process(
        JoinMatchCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
          displayName: 'Bob',
        ),
      );
      await processor.process(
        ReadyPlayerCommand(
          matchId: controller.match!.id,
          playerId: 'host-1',
          isReady: true,
        ),
      );
      await processor.process(
        ReadyPlayerCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
          isReady: true,
        ),
      );
      await processor.process(
        StartMatchCommand(matchId: controller.match!.id, hostId: 'host-1'),
      );

      // Draw round
      await processor.process(StartRoundCommand(matchId: controller.match!.id));
      final round = controller.match!.currentRound!;
      final wordChoice = round.wordOptions.first;
      final drawerId = controller.match!.players
          .firstWhere((p) => p.role == PlayerRole.drawer)
          .playerId;
      final guesserId = controller.match!.players
          .firstWhere((p) => p.playerId != drawerId)
          .playerId;

      await processor.process(
        ChooseWordCommand(
          matchId: controller.match!.id,
          drawerId: drawerId,
          wordId: wordChoice.id,
        ),
      );

      // First guess
      final guessResult = await processor.process(
        SubmitGuessCommand(
          matchId: controller.match!.id,
          playerId: guesserId,
          guessText: 'wrongguess',
        ),
      );
      expect(guessResult.isSuccess, true);

      // Duplicate guess (same player + text)
      final duplicateResult = await processor.process(
        SubmitGuessCommand(
          matchId: controller.match!.id,
          playerId: guesserId,
          guessText: 'wrongguess',
        ),
      );
      expect(duplicateResult.isFailure, true);
      expect(duplicateResult.errorOrThrow, isA<DuplicateCommandFailure>());
    });

    test('4. Player Readiness Mechanism', () async {
      final config = MatchConfiguration(
        minPlayers: 2,
        maxPlayers: 4,
        allowedCategories: const [WordCategory.animals],
      );

      await processor.process(
        CreateMatchCommand(hostId: 'host-1', configuration: config),
      );
      await processor.process(
        JoinMatchCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
          displayName: 'Bob',
        ),
      );

      // Ready host
      final readyRes1 = await processor.process(
        ReadyPlayerCommand(
          matchId: controller.match!.id,
          playerId: 'host-1',
          isReady: true,
        ),
      );
      expect(readyRes1.isSuccess, true);
      expect(controller.match!.playerByPlayerId('host-1')!.isReady, true);

      // Repeat readiness (should fail)
      final duplicateReady = await processor.process(
        ReadyPlayerCommand(
          matchId: controller.match!.id,
          playerId: 'host-1',
          isReady: true,
        ),
      );
      expect(duplicateReady.isFailure, true);
      expect(duplicateReady.errorOrThrow, isA<PlayerAlreadyReadyFailure>());
    });

    test(
      '5. Lifecycle Progression and Validation Rejecting Invalid Transitions',
      () async {
        final config = MatchConfiguration(
          minPlayers: 2,
          maxPlayers: 4,
          allowedCategories: const [WordCategory.animals],
        );

        await processor.process(
          CreateMatchCommand(hostId: 'host-1', configuration: config),
        );

        // Attempt start when players not ready (should fail validation)
        final startFail = await processor.process(
          StartMatchCommand(matchId: controller.match!.id, hostId: 'host-1'),
        );
        expect(startFail.isFailure, true);
        expect(startFail.errorOrThrow, isA<MatchNotReadyFailure>());

        // Join second player and ready all
        await processor.process(
          JoinMatchCommand(
            matchId: controller.match!.id,
            playerId: 'player-2',
            displayName: 'Bob',
          ),
        );
        await processor.process(
          ReadyPlayerCommand(
            matchId: controller.match!.id,
            playerId: 'host-1',
            isReady: true,
          ),
        );
        await processor.process(
          ReadyPlayerCommand(
            matchId: controller.match!.id,
            playerId: 'player-2',
            isReady: true,
          ),
        );

        // Start match successfully
        final startSuccess = await processor.process(
          StartMatchCommand(matchId: controller.match!.id, hostId: 'host-1'),
        );
        expect(startSuccess.isSuccess, true);
        expect(controller.match!.state, isA<MatchStartingState>());

        // Try choosing a word in starting state (invalid transition, round not started)
        final chooseFail = await processor.process(
          ChooseWordCommand(
            matchId: controller.match!.id,
            drawerId: 'host-1',
            wordId: 'word-id',
          ),
        );
        expect(chooseFail.isFailure, true);
        expect(chooseFail.errorOrThrow, isA<UnexpectedCommandFailure>());
      },
    );

    test('6. Clock Timers and Stream Clock State Ticks', () async {
      final clockTicks = <MatchClockState>[];
      final subscription = controller.matchClock.stream.listen(clockTicks.add);

      controller.matchClock.startPreparation(3);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.matchClock.current.type, MatchClockType.preparation);

      controller.matchClock.stop();
      expect(controller.matchClock.current.type, MatchClockType.idle);
      await subscription.cancel();
    });

    test(
      '7. History Integrity & Event Serialization Replay Verification',
      () async {
        final config = MatchConfiguration(
          minPlayers: 2,
          maxPlayers: 4,
          allowedCategories: const [WordCategory.animals],
        );

        await processor.process(
          CreateMatchCommand(hostId: 'host-1', configuration: config),
        );
        await processor.process(
          JoinMatchCommand(
            matchId: controller.match!.id,
            playerId: 'player-2',
            displayName: 'Bob',
          ),
        );
        await processor.process(
          ReadyPlayerCommand(
            matchId: controller.match!.id,
            playerId: 'host-1',
            isReady: true,
          ),
        );
        await processor.process(
          ReadyPlayerCommand(
            matchId: controller.match!.id,
            playerId: 'player-2',
            isReady: true,
          ),
        );
        await processor.process(
          StartMatchCommand(matchId: controller.match!.id, hostId: 'host-1'),
        );
        await processor.process(
          StartRoundCommand(matchId: controller.match!.id),
        );

        final match = controller.match!;
        expect(
          match.eventHistory.length,
          6,
        ); // created, joined, ready, ready, started, roundStarted

        // Verify monotonically increasing sequence numbers
        for (var i = 0; i < match.eventHistory.length; i++) {
          expect(match.eventHistory[i].sequenceNumber, i + 1);
          expect(match.eventHistory[i].eventVersion, 1);
        }

        // JSON Round-trip verification for Match aggregate and transitions
        final serialized = match.toJson();
        final deserialized = Match.fromJson(serialized);
        expect(deserialized.id, match.id);
        expect(deserialized.eventHistory.length, match.eventHistory.length);
        expect(
          deserialized.transitionHistory.length,
          match.transitionHistory.length,
        );
      },
    );
  });
}
