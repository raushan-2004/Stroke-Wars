import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/state_transition.dart';

/// Immutable container wrapping the output of a successful command execution.
class CommandResult {
  const CommandResult({
    required this.resultingState,
    required this.generatedEvents,
    required this.stateTransition,
    required this.executionDuration,
  });

  /// The match state resulting from the command.
  final MatchState resultingState;

  /// All events generated during command execution.
  final List<MatchEvent> generatedEvents;

  /// The audit state transition record.
  final StateTransition stateTransition;

  /// The time taken to execute the command.
  final Duration executionDuration;
}
