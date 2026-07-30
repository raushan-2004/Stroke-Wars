import 'package:stroke_wars/features/match/application/timers/match_clock.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';

/// Immutable context gathering all environmental parameters and engine states
/// present when a command is executed.
class CommandContext {
  const CommandContext({
    required this.command,
    required this.currentMatch,
    this.currentRound,
    this.currentPlayer,
    required this.configuration,
    required this.clockState,
    required this.sequenceNumber,
  });

  /// The command being processed.
  final MatchCommand command;

  /// The active match state aggregate.
  final Match currentMatch;

  /// The active round within the match, if any.
  final Round? currentRound;

  /// The player executing the command, if any.
  final PlayerSlot? currentPlayer;

  /// The match configuration.
  final MatchConfiguration configuration;

  /// The current state of the match clock.
  final MatchClockState clockState;

  /// The next sequence number to assign.
  final int sequenceNumber;
}
