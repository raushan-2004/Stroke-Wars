import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/timer_state.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';

/// Immutable context object passed internally through the domain layer.
///
/// [MatchContext] eliminates the need to pass multiple objects through
/// method signatures. It is rebuilt after every domain mutation.
class MatchContext {
  /// Creates an immutable [MatchContext].
  const MatchContext({
    required this.match,
    required this.configuration,
    this.currentRound,
    this.currentDrawer,
    this.currentWord,
    this.timerState,
  });

  /// Creates a [MatchContext] from a [Match] instance.
  factory MatchContext.from(Match match) => MatchContext(
    match: match,
    configuration: match.configuration,
    currentRound: match.currentRound,
    currentDrawer: match.currentRound != null
        ? match.playerBySlotId(match.currentRound!.drawerSlotId)
        : null,
    currentWord: match.currentRound?.word,
    timerState: match.currentRound?.timerState,
  );

  /// The full match model.
  final Match match;

  /// Convenience access to match configuration.
  final MatchConfiguration configuration;

  /// The currently active round, or null between rounds.
  final Round? currentRound;

  /// The player currently drawing, or null.
  final PlayerSlot? currentDrawer;

  /// The word being drawn, or null before selection.
  final Word? currentWord;

  /// Current timer snapshot, or null when no timer is running.
  final TimerState? timerState;

  /// Whether there is an active round in progress.
  bool get hasActiveRound => currentRound != null;

  /// Whether the current round has a chosen word.
  bool get hasChosenWord => currentWord != null;

  /// Returns a copy with the specified fields replaced.
  MatchContext copyWith({
    Match? match,
    MatchConfiguration? configuration,
    Round? currentRound,
    PlayerSlot? currentDrawer,
    Word? currentWord,
    TimerState? timerState,
  }) => MatchContext(
    match: match ?? this.match,
    configuration: configuration ?? this.configuration,
    currentRound: currentRound ?? this.currentRound,
    currentDrawer: currentDrawer ?? this.currentDrawer,
    currentWord: currentWord ?? this.currentWord,
    timerState: timerState ?? this.timerState,
  );

  @override
  String toString() =>
      'MatchContext(match=${match.id.value.substring(0, 8)}, '
      'round=${currentRound?.roundNumber}, '
      'drawer=${currentDrawer?.displayName})';
}
