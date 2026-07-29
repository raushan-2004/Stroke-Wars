import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/turn_manager.dart';
import 'package:stroke_wars/features/match/domain/models/player_role.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/player_turn.dart';

PlayerSlot _slot(String id, {bool connected = true}) => PlayerSlot(
  slotId: id,
  playerId: 'player_$id',
  displayName: 'Player $id',
  role: PlayerRole.guesser,
  isConnected: connected,
);

TurnManager _manager(List<PlayerSlot> slots) =>
    TurnManager(players: slots, rules: const TurnRules());

void main() {
  group('TurnManager', () {
    group('advance() — basic rotation', () {
      test('first advance returns second slot in round-robin order', () {
        final slots = [_slot('A'), _slot('B'), _slot('C')];
        final manager = _manager(slots);
        // Initially at index 0 (A), advance should go to B
        final next = manager.advance();
        expect(next?.slotId, 'B');
      });

      test('wraps around to first slot after last slot', () {
        final slots = [_slot('A'), _slot('B'), _slot('C')];
        final manager = _manager(slots);
        manager.advance(); // → B
        manager.advance(); // → C
        final next = manager.advance(); // → back to A
        expect(next?.slotId, 'A');
      });

      test('returns null when no players exist', () {
        final manager = _manager([]);
        expect(manager.advance(), isNull);
      });

      test('returns first eligible slot when only one player', () {
        final manager = _manager([_slot('A')]);
        final next = manager.advance();
        // Wraps around and stays at A (only eligible player)
        expect(next?.slotId, 'A');
      });
    });

    group('advance() — skips disconnected players', () {
      test('skips disconnected slot in rotation', () {
        final slots = [_slot('A'), _slot('B', connected: false), _slot('C')];
        final manager = _manager(slots);
        // At A, advance → skip B (disconnected) → C
        final next = manager.advance();
        expect(next?.slotId, 'C');
      });

      test('skips multiple consecutive disconnected slots', () {
        final slots = [
          _slot('A'),
          _slot('B', connected: false),
          _slot('C', connected: false),
          _slot('D'),
        ];
        final manager = _manager(slots);
        final next = manager.advance(); // A → skip B,C → D
        expect(next?.slotId, 'D');
      });

      test('returns null when all players are disconnected', () {
        final slots = [
          _slot('A', connected: false),
          _slot('B', connected: false),
        ];
        final manager = _manager(slots);
        expect(manager.advance(), isNull);
      });
    });

    group('updatePlayers()', () {
      test('updatePlayers reflects disconnection changes', () {
        final slots = [_slot('A'), _slot('B'), _slot('C')];
        final manager = _manager(slots);
        // Disconnect B
        final updated =
            slots.map((s) => s.slotId == 'B' ? s.copyWith(isConnected: false) : s).toList();
        manager.updatePlayers(updated);
        manager.advance(); // from A, should skip B → C
        final drawer = manager.currentDrawer;
        expect(drawer?.slotId, isNot('B'));
      });
    });

    group('recordTurn() and turn history', () {
      test('recordTurn stores completed turns', () {
        final manager = _manager([_slot('A'), _slot('B')]);
        manager.advance();

        final turn = PlayerTurn(
          roundNumber: 1,
          drawerId: 'player_B',
          drawerDisplayName: 'Player B',
          startedAt: DateTime(2026),
          endedAt: DateTime(2026).add(const Duration(seconds: 60)),
          completed: true,
        );
        manager.recordTurn(turn);
        expect(manager.turnHistory.length, 1);
        expect(manager.turnHistory.first.drawerId, 'player_B');
      });

      test('lastTurnFor returns most recent turn for a player', () {
        final manager = _manager([_slot('A'), _slot('B')]);

        final turn1 = PlayerTurn(
          roundNumber: 1,
          drawerId: 'player_A',
          drawerDisplayName: 'Player A',
          startedAt: DateTime(2026),
        );
        final turn2 = PlayerTurn(
          roundNumber: 3,
          drawerId: 'player_A',
          drawerDisplayName: 'Player A',
          startedAt: DateTime(2026).add(const Duration(minutes: 5)),
        );
        manager.recordTurn(turn1);
        manager.recordTurn(turn2);

        final last = manager.lastTurnFor('player_A');
        expect(last?.roundNumber, 3);
      });

      test('turnsForRound returns only matching round turns', () {
        final manager = _manager([_slot('A'), _slot('B')]);
        manager.recordTurn(
          PlayerTurn(roundNumber: 1, drawerId: 'player_A', drawerDisplayName: 'A', startedAt: DateTime(2026)),
        );
        manager.recordTurn(
          PlayerTurn(roundNumber: 2, drawerId: 'player_B', drawerDisplayName: 'B', startedAt: DateTime(2026)),
        );
        manager.recordTurn(
          PlayerTurn(roundNumber: 1, drawerId: 'player_B', drawerDisplayName: 'B', startedAt: DateTime(2026)),
        );

        expect(manager.turnsForRound(1).length, 2);
        expect(manager.turnsForRound(2).length, 1);
      });

      test('drawCountFor returns times a player has drawn', () {
        final manager = _manager([_slot('A'), _slot('B')]);
        manager.recordTurn(
          PlayerTurn(roundNumber: 1, drawerId: 'player_A', drawerDisplayName: 'A', startedAt: DateTime(2026)),
        );
        manager.recordTurn(
          PlayerTurn(roundNumber: 3, drawerId: 'player_A', drawerDisplayName: 'A', startedAt: DateTime(2026)),
        );
        manager.recordTurn(
          PlayerTurn(roundNumber: 2, drawerId: 'player_B', drawerDisplayName: 'B', startedAt: DateTime(2026)),
        );
        expect(manager.drawCountFor('player_A'), 2);
        expect(manager.drawCountFor('player_B'), 1);
      });
    });

    group('reset()', () {
      test('reset clears history and resets index', () {
        final manager = _manager([_slot('A'), _slot('B')]);
        manager.advance();
        manager.recordTurn(
          PlayerTurn(roundNumber: 1, drawerId: 'player_A', drawerDisplayName: 'A', startedAt: DateTime(2026)),
        );

        manager.reset([_slot('X'), _slot('Y')]);

        expect(manager.turnHistory, isEmpty);
        expect(manager.currentDrawer?.slotId, 'X');
      });
    });

    group('6-player rotation', () {
      test('full round-robin visits every player exactly once in 6 advances', () {
        final slots = List.generate(6, (i) => _slot('P$i'));
        final manager = _manager(slots);

        final visited = <String>{};
        for (var i = 0; i < 6; i++) {
          final next = manager.advance();
          expect(next, isNotNull);
          visited.add(next!.slotId);
        }
        // After 6 advances from index 0, every slot should have been visited
        expect(visited.length, 6);
      });
    });
  });
}
