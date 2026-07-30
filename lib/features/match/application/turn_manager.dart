import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/player_turn.dart';

/// Manages mutable turn rotation state during a match.
///
/// [TurnManager] owns the *live* rotation cursor. [PlayerTurn] is the
/// immutable historical record produced after each turn completes.
class TurnManager {
  /// Creates a [TurnManager] for the given [players].
  TurnManager({required List<PlayerSlot> players, required this.rules})
    : _slots = List.unmodifiable(players),
      _currentIndex = 0;

  final TurnRules rules;
  List<PlayerSlot> _slots;
  int _currentIndex;
  final List<PlayerTurn> _turnHistory = [];

  /// Current index of the drawer slot.
  int get currentIndex => _currentIndex;
  set currentIndex(int value) => _currentIndex = value;

  // ───────────────────────────────────────────────────────────────────────────
  // Queries
  // ───────────────────────────────────────────────────────────────────────────

  /// The [PlayerSlot] scheduled to draw on the current/next turn.
  PlayerSlot? get currentDrawer =>
      _slots.isNotEmpty ? _slots[_currentIndex] : null;

  /// Ordered list of all historical turns this match.
  List<PlayerTurn> get turnHistory => List.unmodifiable(_turnHistory);

  /// All player slots known to this manager.
  List<PlayerSlot> get slots => _slots;

  // ───────────────────────────────────────────────────────────────────────────
  // Mutations
  // ───────────────────────────────────────────────────────────────────────────

  /// Updates the player list (e.g. after a player joins or disconnects).
  ///
  /// Preserves the current rotation cursor position where possible.
  void updatePlayers(List<PlayerSlot> players) {
    _slots = List.unmodifiable(players);
    if (_slots.isEmpty) {
      _currentIndex = 0;
    } else {
      _currentIndex = _currentIndex.clamp(0, _slots.length - 1);
    }
  }

  /// Advances to the next eligible drawer, skipping disconnected players.
  ///
  /// Returns the [PlayerSlot] of the new drawer, or null if no eligible
  /// drawer exists.
  PlayerSlot? advance() {
    if (_slots.isEmpty) return null;
    final startIndex = _currentIndex;
    var nextIndex = (_currentIndex + 1) % _slots.length;

    while (nextIndex != startIndex) {
      if (rules.isEligibleDrawer(_slots[nextIndex])) {
        _currentIndex = nextIndex;
        return _slots[_currentIndex];
      }
      nextIndex = (nextIndex + 1) % _slots.length;
    }

    // Wrapped around — check the original position as fallback
    if (rules.isEligibleDrawer(_slots[startIndex])) {
      _currentIndex = startIndex;
      return _slots[_currentIndex];
    }

    return null; // No eligible drawer found
  }

  /// Records a completed [PlayerTurn] to the history log.
  void recordTurn(PlayerTurn turn) => _turnHistory.add(turn);

  /// Returns the last recorded [PlayerTurn] for [drawerId], or null.
  PlayerTurn? lastTurnFor(String drawerId) =>
      _turnHistory.lastWhereOrNull((t) => t.drawerId == drawerId);

  /// Returns all turns for a specific [roundNumber].
  List<PlayerTurn> turnsForRound(int roundNumber) =>
      _turnHistory.where((t) => t.roundNumber == roundNumber).toList();

  /// Returns the number of times [drawerId] has drawn.
  int drawCountFor(String drawerId) =>
      _turnHistory.where((t) => t.drawerId == drawerId).length;

  /// Resets to the initial state (first slot, empty history).
  void reset(List<PlayerSlot> players) {
    _slots = List.unmodifiable(players);
    _currentIndex = 0;
    _turnHistory.clear();
  }
}

extension _ListExt<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
