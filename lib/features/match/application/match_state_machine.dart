import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match_failure.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/result.dart';
import 'package:stroke_wars/features/match/domain/models/state_transition.dart';

/// State machine responsible for validating MatchState transitions and generating
/// immutable StateTransition and MatchEvent outputs.
///
/// Under Stage 5B, this component is purely logical and does not directly mutate
/// the [MatchController] state.
class MatchStateMachine {
  const MatchStateMachine({required this.validator});

  /// The pre-mutation transition and config validator.
  final MatchValidator validator;

  /// Evaluates the requested transition [fromState] → [toState].
  ///
  /// Returns a successful [StateTransition] wrapping the outcome and any
  /// generated events, or returns a [MatchFailure] if the transition is disallowed.
  Result<StateTransition> evaluateTransition({
    required MatchState fromState,
    required MatchState toState,
    required MatchCommand triggerCommand,
    required List<MatchEvent> generatedEvents,
    required DateTime timestamp,
    required String transitionId,
  }) {
    if (fromState.runtimeType != toState.runtimeType) {
      final validation = validator.validateTransition(fromState, toState);
      if (!validation.isValid) {
        return Failure(InvalidTransitionFailure(
          validation.reason ?? 'Cannot transition from ${fromState.label} to ${toState.label}',
        ));
      }
    }

    return Success(StateTransition(
      fromState: fromState,
      toState: toState,
      triggerCommand: triggerCommand,
      generatedEvents: generatedEvents,
      timestamp: timestamp,
      transitionId: transitionId,
    ));
  }
}
