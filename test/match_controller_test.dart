import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/guess_result.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_snapshot.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';

void main() {
  group('MatchController Tests', () {
    late MatchEventBus bus;
    late MatchEventDispatcher dispatcher;
    late MatchValidator validator;
    late RuleEngine rules;
    late ScoringEngine scoring;
    late DefaultWordList wordListRepo;
    late WordSelector wordSelector;
    late MatchController controller;

    setUp(() {
      bus = MatchEventBus();
      dispatcher = MatchEventDispatcher(bus: bus);
      validator = const MatchValidator();
      rules = const RuleEngine();
      scoring = const ScoringEngine();
      wordListRepo = const DefaultWordList();
      wordSelector = WordSelector(
        repository: wordListRepo,
        random: SeededRandomProvider(42),
      );
      controller = MatchController(
        dispatcher: dispatcher,
        validator: validator,
        rules: rules,
        scoring: scoring,
        wordSelector: wordSelector,
      );
    });

    tearDown(() {
      bus.dispose();
    });

    test('CreateMatchCommand initializes match and transitions to waiting state', () async {
      final events = <MatchEvent>[];
      final sub = bus.stream.listen(events.add);

      const config = MatchConfiguration(
        minPlayers: 2,
        maxPlayers: 4,
        totalRounds: 3,
      );

      await controller.execute(
        const CreateMatchCommand(
          hostId: 'host-123',
          configuration: config,
        ),
      );

      expect(controller.match, isNotNull);
      expect(controller.match!.state, isA<MatchWaitingState>());
      expect(controller.match!.hostId, 'host-123');
      expect(controller.match!.players.length, 1);
      expect(controller.match!.players.first.playerId, 'host-123');
      expect(controller.match!.players.first.role, PlayerRole.host);

      expect(events.length, 1);
      expect(events[0], isA<MatchCreatedEvent>());
      final createdEvent = events[0] as MatchCreatedEvent;
      expect(createdEvent.hostId, 'host-123');

      await sub.cancel();
    });

    test('JoinMatchCommand adds player to waiting match', () async {
      final events = <MatchEvent>[];
      final sub = bus.stream.listen(events.add);

      await controller.execute(
        const CreateMatchCommand(
          hostId: 'host-123',
          configuration: MatchConfiguration(minPlayers: 2, maxPlayers: 3),
        ),
      );

      await controller.execute(
        JoinMatchCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
          displayName: 'Bob',
        ),
      );

      expect(controller.match!.players.length, 2);
      expect(controller.match!.players[1].playerId, 'player-2');
      expect(controller.match!.players[1].displayName, 'Bob');
      expect(controller.match!.players[1].role, PlayerRole.guesser);

      expect(events.length, 2);
      expect(events[1], isA<PlayerJoinedEvent>());
      final joinedEvent = events[1] as PlayerJoinedEvent;
      expect(joinedEvent.playerId, 'player-2');
      expect(joinedEvent.displayName, 'Bob');

      await sub.cancel();
    });

    test('LeaveMatchCommand updates player connection state', () async {
      await controller.execute(
        const CreateMatchCommand(
          hostId: 'host-123',
          configuration: MatchConfiguration(),
        ),
      );

      await controller.execute(
        JoinMatchCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
          displayName: 'Bob',
        ),
      );

      await controller.execute(
        LeaveMatchCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
        ),
      );

      expect(controller.match!.players[1].isConnected, isFalse);
      expect(controller.match!.connectedPlayers.length, 1);
    });

    test('StartMatchCommand shifts match to starting state', () async {
      final events = <MatchEvent>[];
      final sub = bus.stream.listen(events.add);

      await controller.execute(
        const CreateMatchCommand(
          hostId: 'host-123',
          configuration: MatchConfiguration(minPlayers: 2),
        ),
      );

      await controller.execute(
        JoinMatchCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
          displayName: 'Bob',
        ),
      );

      // Make Bob and Host ready
      final updatedPlayers = controller.match!.players.map((p) => p.copyWith(isReady: true)).toList();
      controller.match = controller.match!.copyWith(players: updatedPlayers);

      await controller.execute(
        StartMatchCommand(
          matchId: controller.match!.id,
          hostId: 'host-123',
        ),
      );

      expect(controller.match!.state, isA<MatchStartingState>());
      expect(events.last, isA<MatchStartedEvent>());

      await sub.cancel();
    });

    test('Full gameplay flow: choose word, guess, end round, and finish match', () async {
      final events = <MatchEvent>[];
      final sub = bus.stream.listen(events.add);

      // 1. Create match
      await controller.execute(
        const CreateMatchCommand(
          hostId: 'host-123',
          configuration: MatchConfiguration(
            minPlayers: 2,
            allowedCategories: [WordCategory.animals],
          ),
        ),
      );

      // 2. Bob Joins
      await controller.execute(
        JoinMatchCommand(
          matchId: controller.match!.id,
          playerId: 'player-2',
          displayName: 'Bob',
        ),
      );

      // Set ready
      controller.match = controller.match!.copyWith(
        players: controller.match!.players.map((p) => p.copyWith(isReady: true)).toList(),
      );

      // 3. Start Match
      await controller.execute(
        StartMatchCommand(
          matchId: controller.match!.id,
          hostId: 'host-123',
        ),
      );

      // Transition validator allows starting state to transition directly to word selection when starting round
      controller.match = controller.match!.copyWith(state: const MatchStartingState());

      // 4. Start Round 1
      await controller.execute(StartRoundCommand(matchId: controller.match!.id));

      expect(controller.match!.state, isA<WordSelectionState>());
      expect(controller.match!.currentRound, isNotNull);
      expect(controller.match!.currentRound!.wordOptions.length, 3);

      final wordChoice = controller.match!.currentRound!.wordOptions.first;
      final drawerId = controller.match!.players.firstWhere((p) => p.role == PlayerRole.drawer).playerId;

      // 5. Choose Word
      await controller.execute(
        ChooseWordCommand(
          matchId: controller.match!.id,
          drawerId: drawerId,
          wordId: wordChoice.id,
        ),
      );

      expect(controller.match!.state, isA<DrawingState>());
      expect(controller.match!.currentRound!.state, isA<RoundActiveState>());
      expect(controller.match!.currentRound!.word, wordChoice);

      // 6. Submit incorrect and correct guesses
      final guesser = controller.match!.players.firstWhere((p) => p.playerId != drawerId);
      
      await controller.execute(
        SubmitGuessCommand(
          matchId: controller.match!.id,
          playerId: guesser.playerId,
          guessText: 'wrongguess',
        ),
      );

      expect(controller.match!.currentRound!.guesses.length, 1);
      expect(controller.match!.currentRound!.guesses.first.result, GuessResult.incorrect);

      await controller.execute(
        SubmitGuessCommand(
          matchId: controller.match!.id,
          playerId: guesser.playerId,
          guessText: wordChoice.text,
        ),
      );

      expect(controller.match!.currentRound!.guesses.length, 2);
      expect(controller.match!.currentRound!.guesses[1].result, GuessResult.correct);

      // 7. End the round
      // Adjust states manually to make transition validator happy if needed
      controller.match = controller.match!.copyWith(state: const DrawingState());

      await controller.execute(
        EndRoundCommand(
          matchId: controller.match!.id,
          reason: 'time_expired',
        ),
      );

      expect(controller.match!.state, isA<RoundFinishedState>());
      expect(controller.match!.currentRound!.state, isA<RoundFinishedRoundState>());
      // Drawer should receive bonus, guesser receives correct guess points
      expect(controller.match!.currentRound!.scores.length, 2);

      // 8. Finish the match
      await controller.execute(FinishMatchCommand(matchId: controller.match!.id));

      expect(controller.match!.state, isA<MatchFinishedState>());
      expect(controller.match!.result, isNotNull);

      await sub.cancel();
    });

    test('CancelMatchCommand transitions state to cancelled', () async {
      await controller.execute(
        const CreateMatchCommand(
          hostId: 'host-123',
          configuration: MatchConfiguration(),
        ),
      );

      await controller.execute(
        CancelMatchCommand(
          matchId: controller.match!.id,
          reason: 'host_left',
        ),
      );

      expect(controller.match!.state, isA<MatchCancelledState>());
    });

    test('Snapshot capture and restore matching', () async {
      await controller.execute(
        const CreateMatchCommand(
          hostId: 'host-123',
          configuration: MatchConfiguration(totalRounds: 5),
        ),
      );

      final snap = controller.takeSnapshot();
      expect(snap, isNotNull);
      expect(snap!.matchState, 'waiting');
      expect(snap.configuration.totalRounds, 5);

      final json = snap.toJson();
      final restored = MatchSnapshot.fromJson(json);
      expect(restored.matchId, snap.matchId);
      expect(restored.configuration.totalRounds, 5);
    });
  });
}
