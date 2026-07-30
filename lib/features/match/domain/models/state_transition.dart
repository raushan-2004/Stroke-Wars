import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';

/// Immutable model representing an audit record of a state transition
/// triggered in a match.
class StateTransition {
  const StateTransition({
    required this.fromState,
    required this.toState,
    required this.triggerCommand,
    required this.generatedEvents,
    required this.timestamp,
    required this.transitionId,
  });

  /// Factory constructor to parse a [StateTransition] from a JSON map.
  factory StateTransition.fromJson(Map<String, dynamic> json) {
    return StateTransition(
      fromState: _stateFromJson(json['fromState'] as String),
      toState: _stateFromJson(json['toState'] as String),
      triggerCommand: _commandFromJson(json['triggerCommand'] as Map<String, dynamic>),
      generatedEvents: (json['generatedEvents'] as List<dynamic>)
          .map((e) => MatchEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      transitionId: json['transitionId'] as String,
    );
  }

  final MatchState fromState;
  final MatchState toState;
  final MatchCommand triggerCommand;
  final List<MatchEvent> generatedEvents;
  final DateTime timestamp;
  final String transitionId;

  /// Converts this [StateTransition] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'fromState': _stateToJson(fromState),
    'toState': _stateToJson(toState),
    'triggerCommand': _commandToJson(triggerCommand),
    'generatedEvents': generatedEvents.map((e) => e.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
    'transitionId': transitionId,
  };

  static MatchState _stateFromJson(String name) => switch (name) {
    'created' => const MatchCreatedState(),
    'waiting' => const MatchWaitingState(),
    'starting' => const MatchStartingState(),
    'wordSelection' => const WordSelectionState(),
    'drawing' => const DrawingState(),
    'guessing' => const GuessingState(),
    'roundFinished' => const RoundFinishedState(),
    'scoreboard' => const ScoreboardState(),
    'matchFinished' => const MatchFinishedState(),
    'cancelled' => const MatchCancelledState(),
    _ => const MatchCreatedState(),
  };

  static String _stateToJson(MatchState state) => switch (state) {
    MatchCreatedState() => 'created',
    MatchWaitingState() => 'waiting',
    MatchStartingState() => 'starting',
    WordSelectionState() => 'wordSelection',
    DrawingState() => 'drawing',
    GuessingState() => 'guessing',
    RoundFinishedState() => 'roundFinished',
    ScoreboardState() => 'scoreboard',
    MatchFinishedState() => 'matchFinished',
    MatchCancelledState() => 'cancelled',
  };

  static Map<String, dynamic> _commandToJson(MatchCommand command) {
    // Simple command representation for serialization/auditing
    return {
      'type': command.runtimeType.toString(),
      // We can add other parameters if needed, or serialize a generic fallback
    };
  }

  static MatchCommand _commandFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    // Return a dummy command matching the type for audit purposes
    switch (type) {
      case 'CreateMatchCommand':
        return const DummyMatchCommand('CreateMatchCommand');
      case 'JoinMatchCommand':
        return const DummyMatchCommand('JoinMatchCommand');
      case 'LeaveMatchCommand':
        return const DummyMatchCommand('LeaveMatchCommand');
      case 'StartMatchCommand':
        return const DummyMatchCommand('StartMatchCommand');
      case 'ChooseWordCommand':
        return const DummyMatchCommand('ChooseWordCommand');
      case 'SubmitGuessCommand':
        return const DummyMatchCommand('SubmitGuessCommand');
      case 'SkipTurnCommand':
        return const DummyMatchCommand('SkipTurnCommand');
      case 'EndRoundCommand':
        return const DummyMatchCommand('EndRoundCommand');
      case 'FinishMatchCommand':
        return const DummyMatchCommand('FinishMatchCommand');
      case 'CancelMatchCommand':
        return const DummyMatchCommand('CancelMatchCommand');
      default:
        return const DummyMatchCommand('Unknown');
    }
  }
}
