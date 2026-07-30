import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';

/// Result of a [MatchValidator] check.
class ValidationResult {
  /// Creates a [ValidationResult].
  const ValidationResult({required this.isValid, this.reason});

  /// Returns a passing result.
  const ValidationResult.ok() : isValid = true, reason = null;

  /// Returns a failing result with an explanatory [reason].
  const ValidationResult.fail(String message)
    : isValid = false,
      reason = message;

  /// Whether the validation passed.
  final bool isValid;

  /// Human-readable explanation when [isValid] is false.
  final String? reason;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $reason';
}

/// Validates state transitions, configuration, and player integrity.
///
/// All rule checking happens here before [MatchController] mutates state.
/// [MatchController] never assumes a transition is legal without asking
/// [MatchValidator] first.
class MatchValidator {
  /// Creates a [MatchValidator].
  const MatchValidator();

  // ───────────────────────────────────────────────────────────────────────────
  // State transition validation
  // ───────────────────────────────────────────────────────────────────────────

  /// Validates that transitioning [from] → [to] is a legal state change.
  ValidationResult validateTransition(MatchState from, MatchState to) {
    final allowed = _allowedTransitions[from.runtimeType] ?? const {};
    if (allowed.contains(to.runtimeType)) return const ValidationResult.ok();
    return ValidationResult.fail(
      'Cannot transition from ${from.label} to ${to.label}',
    );
  }

  static const Map<Type, Set<Type>> _allowedTransitions = {
    MatchCreatedState: {MatchWaitingState, MatchCancelledState},
    MatchWaitingState: {MatchStartingState, MatchCancelledState},
    MatchStartingState: {WordSelectionState, MatchCancelledState},
    WordSelectionState: {DrawingState, MatchCancelledState},
    DrawingState: {GuessingState, RoundFinishedState, MatchCancelledState},
    GuessingState: {RoundFinishedState, MatchCancelledState},
    RoundFinishedState: {ScoreboardState, MatchFinishedState, MatchCancelledState},
    ScoreboardState: {
      WordSelectionState, // next round
      MatchFinishedState,
      MatchCancelledState,
    },
    MatchFinishedState: {},
    MatchCancelledState: {},
  };

  // ───────────────────────────────────────────────────────────────────────────
  // Configuration validation
  // ───────────────────────────────────────────────────────────────────────────

  /// Validates that a [MatchConfiguration] is internally consistent.
  ValidationResult validateConfiguration(MatchConfiguration config) {
    if (config.maxPlayers < 2) {
      return const ValidationResult.fail('maxPlayers must be at least 2');
    }
    if (config.minPlayers < 2) {
      return const ValidationResult.fail('minPlayers must be at least 2');
    }
    if (config.minPlayers > config.maxPlayers) {
      return const ValidationResult.fail(
        'minPlayers cannot exceed maxPlayers',
      );
    }
    if (config.totalRounds < 1) {
      return const ValidationResult.fail('totalRounds must be at least 1');
    }
    if (config.totalRounds > 20) {
      return const ValidationResult.fail('totalRounds cannot exceed 20');
    }
    if (config.drawTimeSecs < 10) {
      return const ValidationResult.fail('drawTimeSecs must be at least 10');
    }
    if (config.drawTimeSecs > 300) {
      return const ValidationResult.fail('drawTimeSecs cannot exceed 300');
    }
    if (config.wordChoiceCount < 1) {
      return const ValidationResult.fail('wordChoiceCount must be at least 1');
    }
    if (config.wordChoiceCount > 5) {
      return const ValidationResult.fail('wordChoiceCount cannot exceed 5');
    }
    if (config.allowedCategories.isEmpty) {
      return const ValidationResult.fail(
        'allowedCategories must not be empty',
      );
    }
    return const ValidationResult.ok();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Player limit validation
  // ───────────────────────────────────────────────────────────────────────────

  /// Validates that a new player can join given current [players] and [config].
  ValidationResult validatePlayerJoin(
    List<PlayerSlot> players,
    MatchConfiguration config,
  ) {
    final connected = players.where((p) => p.isConnected).length;
    if (connected >= config.maxPlayers) {
      return ValidationResult.fail(
        'Match is full (${config.maxPlayers} players)',
      );
    }
    return const ValidationResult.ok();
  }

  /// Validates that the match has enough players to start.
  ValidationResult validateReadyToStart(
    List<PlayerSlot> players,
    MatchConfiguration config,
  ) {
    final connected = players.where((p) => p.isConnected).length;
    if (connected < config.minPlayers) {
      return ValidationResult.fail(
        'Need at least ${config.minPlayers} players to start '
        '(have $connected)',
      );
    }
    return const ValidationResult.ok();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Turn integrity validation
  // ───────────────────────────────────────────────────────────────────────────

  /// Validates that [drawerId] is allowed to draw (is connected and has role).
  ValidationResult validateDrawerEligibility(
    String drawerId,
    List<PlayerSlot> players,
  ) {
    final slot = players.where((p) => p.playerId == drawerId).firstOrNull;
    if (slot == null) {
      return const ValidationResult.fail('Drawer not found in player list');
    }
    if (!slot.isConnected) {
      return const ValidationResult.fail(
        'Drawer is disconnected and cannot draw',
      );
    }
    return const ValidationResult.ok();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Scoring rules validation
  // ───────────────────────────────────────────────────────────────────────────

  /// Validates that [guessTimeMs] is a plausible value within [maxTimeSecs].
  ValidationResult validateGuessTime(int guessTimeMs, int maxTimeSecs) {
    if (guessTimeMs < 0) {
      return const ValidationResult.fail('guessTimeMs cannot be negative');
    }
    if (guessTimeMs > maxTimeSecs * 1000) {
      return const ValidationResult.fail(
        'guessTimeMs exceeds the round draw duration',
      );
    }
    return const ValidationResult.ok();
  }
}
