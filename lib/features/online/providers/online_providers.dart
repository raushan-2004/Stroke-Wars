import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/online/application/online_session_controller.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
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
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';

part 'online_providers.g.dart';

/// Riverpod provider adapter for accessing the [OnlineSessionController] and the active [OnlineSession] state.
@riverpod
class OnlineSessionStateNotifier extends _$OnlineSessionStateNotifier {
  late final OnlineSessionController _controller;

  @override
  OnlineSession build() {
    final canvas = ref.watch(canvasControllerProvider);
    final drawingBus = ref.watch(drawingEventBusProvider);

    final matchEventBus = MatchEventBus();
    final matchController = MatchController(
      dispatcher: MatchEventDispatcher(bus: matchEventBus),
      validator: MatchValidator(),
      rules: RuleEngine(
        wordRules: const WordRules(),
        victoryRules: const VictoryRules(),
        configurationRules: const ConfigurationRules(),
      ),
      scoring: const ScoringEngine(),
      wordSelector: WordSelector(
        repository: const DefaultWordList(),
        random: DefaultRandomProvider(),
      ),
      clock: const SystemClock(),
      sequenceGenerator: SequenceGenerator(),
    );

    final commandProcessor = MatchCommandProcessor(
      controller: matchController,
      stateMachine: MatchStateMachine(validator: MatchValidator()),
      clock: const SystemClock(),
    );

    _controller = OnlineSessionController(
      matchController: matchController,
      canvasController: canvas,
      commandProcessor: commandProcessor,
      matchEventBus: matchEventBus,
      drawingEventBus: drawingBus,
    );

    _controller.addListener((newSession) {
      state = newSession;
    });

    ref.onDispose(() {
      _controller.dispose();
    });

    return _controller.session;
  }

  /// Exposes the plain Dart [OnlineSessionController] instance.
  OnlineSessionController get controller => _controller;
}
