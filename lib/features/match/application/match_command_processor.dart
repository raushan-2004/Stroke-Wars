import 'package:stroke_wars/core/utils/uuid.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_state_machine.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/command_context.dart';
import 'package:stroke_wars/features/match/domain/models/command_result.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_failure.dart';
import 'package:stroke_wars/features/match/domain/models/guess_result.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/result.dart';
import 'package:stroke_wars/features/match/domain/models/state_transition.dart';

/// Processor responsible for coordinating command context creation, validation,
/// state transitions, and event emission.
class MatchCommandProcessor {
  const MatchCommandProcessor({
    required this.controller,
    required this.stateMachine,
    required this.clock,
  });

  /// The match orchestrator.
  final MatchController controller;

  /// The state transition validator machine.
  final MatchStateMachine stateMachine;

  /// The clock provider.
  final ClockProvider clock;

  /// Processes the given [command] in the match gameplay loop.
  ///
  /// Returns a successful [CommandResult] containing the outcome and events,
  /// or a [MatchFailure] if processing fails.
  Future<Result<CommandResult>> process(MatchCommand command) async {
    final startTime = clock.now;

    // 1. Build CommandContext
    final contextResult = _buildContext(command);
    if (contextResult.isFailure) {
      return Failure(contextResult.errorOrThrow);
    }
    final context = contextResult.valueOrThrow;

    // 2. Validate preconditions
    final preValidation = _validatePreconditions(context);
    if (preValidation.isFailure) {
      return Failure(preValidation.errorOrThrow);
    }

    // 3. Dry-run execution
    final dryRunResult = await controller.dryRun(context);
    if (dryRunResult.isFailure) {
      return Failure(dryRunResult.errorOrThrow);
    }
    final outcome = dryRunResult.valueOrThrow;

    // 4. Validate transition
    final transitionResult = stateMachine.evaluateTransition(
      fromState: context.currentMatch.state,
      toState: outcome.toState,
      triggerCommand: command,
      generatedEvents: outcome.events,
      timestamp: clock.now,
      transitionId: generateV4Uuid(),
    );
    if (transitionResult.isFailure) {
      return Failure(transitionResult.errorOrThrow);
    }
    final transition = transitionResult.valueOrThrow;

    // 5. Apply transition and mutate controller state
    controller.applyTransition(transition, outcome.mutatedMatch);

    final duration = clock.now.difference(startTime);
    return Success(CommandResult(
      resultingState: outcome.toState,
      generatedEvents: outcome.events,
      stateTransition: transition,
      executionDuration: duration,
    ));
  }

  Result<CommandContext> _buildContext(MatchCommand command) {
    final currentMatch = controller.match;

    // CreateMatchCommand is allowed when no match exists yet
    if (command is CreateMatchCommand) {
      final mockMatch = Match(
        id: MatchId('temp'),
        hostId: command.hostId,
        configuration: command.configuration,
        players: const [],
        rounds: const [],
        state: const MatchCreatedState(),
        createdAt: clock.now,
      );
      return Success(CommandContext(
        command: command,
        currentMatch: mockMatch,
        configuration: command.configuration,
        clockState: controller.matchClock.current,
        sequenceNumber: controller.sequenceGenerator.current + 1,
      ));
    }

    if (currentMatch == null) {
      return const Failure(InvalidTransitionFailure('No active match loaded in controller.'));
    }

    String? playerId;
    if (command is JoinMatchCommand) playerId = command.playerId;
    if (command is LeaveMatchCommand) playerId = command.playerId;
    if (command is ReadyPlayerCommand) playerId = command.playerId;
    if (command is StartMatchCommand) playerId = command.hostId;
    if (command is ChooseWordCommand) playerId = command.drawerId;
    if (command is SubmitGuessCommand) playerId = command.playerId;
    if (command is SkipTurnCommand) playerId = command.drawerId;

    PlayerSlot? currentPlayer;
    if (playerId != null) {
      currentPlayer = currentMatch.playerByPlayerId(playerId);
    }

    return Success(CommandContext(
      command: command,
      currentMatch: currentMatch,
      currentRound: currentMatch.currentRound,
      currentPlayer: currentPlayer,
      configuration: currentMatch.configuration,
      clockState: controller.matchClock.current,
      sequenceNumber: controller.sequenceGenerator.current + 1,
    ));
  }

  Result<void> _validatePreconditions(CommandContext context) {
    final cmd = context.command;
    final match = context.currentMatch;

    // Check duplicate command
    final isDuplicate = match.commandHistory.any((c) =>
        c.runtimeType == cmd.runtimeType &&
        _isDuplicateDetails(c, cmd));
    if (isDuplicate) {
      return Failure(DuplicateCommandFailure(cmd.runtimeType.toString()));
    }

    if (cmd is JoinMatchCommand) {
      if (match.state is! MatchCreatedState && match.state is! MatchWaitingState) {
        return Failure(UnexpectedCommandFailure(cmd.runtimeType.toString(), match.state.label));
      }
      final existing = match.playerByPlayerId(cmd.playerId);
      if (existing != null && existing.isConnected) {
        return const Failure(InvalidTransitionFailure('Player already joined match.'));
      }
    }

    if (cmd is ReadyPlayerCommand) {
      if (match.state is! MatchWaitingState && match.state is! MatchCreatedState) {
        return Failure(UnexpectedCommandFailure(cmd.runtimeType.toString(), match.state.label));
      }
      if (context.currentPlayer == null) {
        return Failure(PlayerNotFoundFailure(cmd.playerId));
      }
      if (context.currentPlayer!.isReady == cmd.isReady) {
        return Failure(PlayerAlreadyReadyFailure(cmd.playerId));
      }
    }

    if (cmd is StartMatchCommand) {
      if (match.state is! MatchWaitingState) {
        return Failure(UnexpectedCommandFailure(cmd.runtimeType.toString(), match.state.label));
      }
      if (match.hostId != cmd.hostId) {
        return const Failure(InvalidTransitionFailure('Only host can start the match.'));
      }
      final readyRes = controller.validator.validateReadyToStart(match.players, match.configuration);
      if (!readyRes.isValid) {
        return Failure(MatchNotReadyFailure(readyRes.reason ?? 'Match not ready.'));
      }
    }

    if (cmd is ChooseWordCommand) {
      if (match.state is! WordSelectionState) {
        return Failure(UnexpectedCommandFailure(cmd.runtimeType.toString(), match.state.label));
      }
      if (context.currentRound == null) {
        return const Failure(InvalidTransitionFailure('No active round.'));
      }
      if (context.currentRound!.drawerSlotId != context.currentPlayer?.slotId &&
          context.currentRound!.drawerSlotId != cmd.drawerId) {
        return const Failure(InvalidTransitionFailure('Only the drawer can choose the word.'));
      }
    }

    if (cmd is SubmitGuessCommand) {
      if (match.state is! DrawingState && match.state is! GuessingState) {
        return Failure(UnexpectedCommandFailure(cmd.runtimeType.toString(), match.state.label));
      }
      if (context.currentRound == null) {
        return const Failure(InvalidTransitionFailure('No active round.'));
      }
      if (context.currentPlayer == null) {
        return Failure(PlayerNotFoundFailure(cmd.playerId));
      }
      if (context.currentPlayer!.slotId == context.currentRound!.drawerSlotId) {
        return const Failure(InvalidTransitionFailure('Drawer cannot submit guesses.'));
      }
      final alreadyGuessed = context.currentRound!.guesses.any((g) =>
          g.playerId == cmd.playerId && g.result == GuessResult.correct);
      if (alreadyGuessed) {
        return const Failure(DuplicateCommandFailure('Correct guess already submitted.'));
      }
    }

    return const Success(null);
  }

  bool _isDuplicateDetails(MatchCommand c1, MatchCommand c2) {
    if (c1 is SubmitGuessCommand && c2 is SubmitGuessCommand) {
      return c1.playerId == c2.playerId && c1.guessText == c2.guessText;
    }
    if (c1 is ChooseWordCommand && c2 is ChooseWordCommand) {
      return c1.drawerId == c2.drawerId && c1.wordId == c2.wordId;
    }
    return false;
  }
}
