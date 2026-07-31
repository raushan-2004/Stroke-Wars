import 'dart:ui';
import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_snapshot.dart';

/// Service responsible for parsing snapshots/deltas and applying them to MatchController and CanvasController.
class SnapshotApplier {
  SnapshotApplier({
    required this.matchController,
    required this.canvasController,
  });

  final MatchController matchController;
  final CanvasController canvasController;

  int _lastSeenSnapshotSequence = -1;

  /// Resets internal sequence tracking.
  void reset() {
    _lastSeenSnapshotSequence = -1;
  }

  /// Appiles a RoomSnapshot authoritatively to the local Match and Canvas engines.
  bool applySnapshot(RoomSnapshot snapshot, String hostId) {
    if (snapshot.sequenceNumber < _lastSeenSnapshotSequence) {
      AppLogger.instance.warning(
        'SnapshotApplier: Rejected stale snapshot (seq=${snapshot.sequenceNumber}, expected >= $_lastSeenSnapshotSequence)',
      );
      return false; // Stale snapshot, ignore
    }
    _lastSeenSnapshotSequence = snapshot.sequenceNumber;

    // Restore Match State
    final matchSnap = snapshot.matchSnapshot;
    if (matchSnap != null) {
      final rebuiltMatch = Match(
        id: matchSnap.matchId,
        hostId: hostId,
        configuration: matchSnap.configuration,
        players: matchSnap.players,
        rounds: matchSnap.rounds,
        state: _stringToState(matchSnap.matchState),
        createdAt: matchSnap.capturedAt,
      );
      matchController.match = rebuiltMatch;
    } else {
      matchController.match = null;
    }

    // Mirror Canvas drawings
    canvasController.resetHistory();
    for (final event in snapshot.drawingEvents) {
      applyDrawingEvent(event);
    }

    return true;
  }

  /// Applies a delta/drawing event directly to the canvas.
  void applyDrawingEvent(DrawingEvent event) {
    if (event is StrokeStarted) {
      final clean = event.color.replaceAll('#', '');
      final color = clean.length == 6
          ? Color(int.parse('FF$clean', radix: 16))
          : Color(int.parse(clean, radix: 16));

      canvasController.startStroke(
        event.playerId,
        canvasController.state.selectedBrush.copyWith(
          color: color,
          size: event.width,
          opacity: event.opacity,
        ),
      );
    } else if (event is PointAdded) {
      canvasController.appendPoint(
        event.point.x,
        event.point.y,
        pressure: event.point.pressure,
        velocity: event.point.velocity,
      );
    } else if (event is StrokeFinished) {
      canvasController.finishStroke();
    } else if (event is CanvasCleared) {
      canvasController.clear();
    } else if (event is UndoPerformed) {
      canvasController.undo();
    } else if (event is RedoPerformed) {
      canvasController.redo();
    }
  }

  MatchState _stringToState(String stateStr) {
    switch (stateStr) {
      case 'created':
        return const MatchCreatedState();
      case 'waiting':
        return const MatchWaitingState();
      case 'starting':
        return const MatchStartingState();
      case 'wordSelection':
        return const WordSelectionState();
      case 'drawing':
        return const DrawingState();
      case 'guessing':
        return const GuessingState();
      case 'roundFinished':
        return const RoundFinishedState();
      case 'scoreboard':
        return const ScoreboardState();
      case 'matchFinished':
        return const MatchFinishedState();
      case 'cancelled':
        return const MatchCancelledState();
      default:
        return const MatchCreatedState();
    }
  }
}
