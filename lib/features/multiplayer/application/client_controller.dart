import 'dart:async';
import 'dart:ui';

import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/lan/application/synchronization_manager.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/multiplayer/application/connection_manager.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_snapshot.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';

/// Non-authoritative client-side mirror plain Dart controller.
///
/// Joins/leaves rooms, routes drawing/match commands to the Host, and syncs
/// local mirror Canvas/Match engine state via authoritative snapshots and events.
class ClientController {
  ClientController({
    required this.connectionManager,
    required this.matchController,
    required this.canvasController,
    required this.matchEventBus,
    SynchronizationManager? synchronizationManager,
  }) : synchronizationManager =
           synchronizationManager ??
           SynchronizationManager(
             matchController: matchController,
             canvasController: canvasController,
             onStateChanged: (_, __) {},
           ) {
    _init();
  }

  final ConnectionManager connectionManager;
  final MatchController matchController;
  final CanvasController canvasController;
  final MatchEventBus matchEventBus;
  final SynchronizationManager synchronizationManager;

  Room? _room;
  final StreamController<Room> _roomStreamController =
      StreamController<Room>.broadcast();

  StreamSubscription<NetworkEnvelope>? _inboundMessageSub;
  StreamSubscription<NetworkConnectionState>? _connectionStateSub;

  int _lastSeenSnapshotSequence = -1;

  Room? get room => _room;
  Stream<Room> get onRoomChanged => _roomStreamController.stream;
  Stream<NetworkConnectionState> get connectionState =>
      connectionManager.connectionState;

  void _init() {
    _inboundMessageSub = connectionManager.inboundMessages.listen(
      _handleInboundMessage,
    );
    _connectionStateSub = connectionManager.connectionState.listen(
      _handleConnectionStateChange,
    );
  }

  /// Sends a request to join a remote multiplayer room.
  Future<void> joinRoom(String address, int port, PeerInfo localPeer) async {
    _room = null;
    _lastSeenSnapshotSequence = -1;

    // Connect transport first
    await connectionManager.connect(address, port);

    // Send JoinRoom message payload
    await connectionManager.sendPayload(JoinRoomMessage(peerInfo: localPeer));
  }

  /// Voluntarily departs the room.
  Future<void> leaveRoom(String playerId) async {
    if (_room == null) return;
    await connectionManager.sendPayload(
      LeaveRoomMessage(peerId: playerId, reason: 'Voluntary depart'),
    );
    await connectionManager.disconnect();
    final oldRoom = _room;
    _room = null;
    if (oldRoom != null) {
      _roomStreamController.add(
        Room(
          id: oldRoom.id,
          configuration: oldRoom.configuration,
          state: RoomState.closed,
          host: oldRoom.host,
          players: const [],
        ),
      );
    }
  }

  /// Sends a gameplay command intent to the authoritative Host.
  void sendCommand(MatchCommand command) {
    connectionManager.sendPayload(MatchCommandMessage(command: command));
  }

  /// Sends a drawing canvas event to the authoritative Host.
  void sendCanvasEvent(DrawingEvent event) {
    connectionManager.sendPayload(CanvasEventMessage(event: event));
  }

  void _handleInboundMessage(NetworkEnvelope envelope) {
    try {
      final msg = connectionManager.serializer.decodePayload(envelope);

      // Delegate sequence, duplicate and state tracking to SynchronizationManager
      final allowed = synchronizationManager.processInboundEnvelope(
        envelope: envelope,
        message: msg,
        isHost: false,
        activeDrawerId: matchController.match?.currentRound?.drawerSlotId,
        roomPlayerIds:
            _room?.players.map((p) => p.peerInfo.id.value).toList() ?? const [],
        connectionIdToPlayerIdMap: const {},
      );

      if (!allowed) return;

      if (msg is SnapshotMessage) {
        _handleSnapshot(msg.snapshot);
      } else if (msg is MatchEventMessage) {
        _handleMatchEvent(msg.event);
      } else if (msg is CanvasEventMessage) {
        _handleCanvasEvent(msg.event);
      } else if (msg is LeaveRoomMessage) {
        // Disconnected/Kicked by host
        connectionManager.disconnect();
      } else if (msg is ErrorMessage) {
        AppLogger.instance.error(
          'Received Error from Host: [${msg.code}] ${msg.message}',
        );
      }
    } catch (e) {
      AppLogger.instance.error('ClientController error processing payload: $e');
    }
  }

  void _handleSnapshot(RoomSnapshot snapshot) {
    // Ignore stale snapshots
    if (snapshot.sequenceNumber < _lastSeenSnapshotSequence) {
      return;
    }
    _lastSeenSnapshotSequence = snapshot.sequenceNumber;

    _room = snapshot.room;
    _roomStreamController.add(_room!);

    // Reconstruct match state
    final matchSnap = snapshot.matchSnapshot;
    if (matchSnap != null) {
      final rebuiltMatch = Match(
        id: matchSnap.matchId,
        hostId: _room!.host.id.value,
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

    // Mirror canvas drawings
    canvasController.resetHistory();
    for (final event in snapshot.drawingEvents) {
      _applyDrawingEventToLocalMirror(event);
    }
  }

  void _handleMatchEvent(MatchEvent event) {
    // Publish match event to client's local event bus so local UI listens/animates
    matchEventBus.publish(event);
  }

  void _handleCanvasEvent(DrawingEvent event) {
    // Apply drawing event to local canvas renderer
    _applyDrawingEventToLocalMirror(event);
  }

  void _applyDrawingEventToLocalMirror(DrawingEvent event) {
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

  void _handleConnectionStateChange(NetworkConnectionState state) {
    if (state == NetworkConnectionState.disconnected) {
      _room = null;
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

  void dispose() {
    _inboundMessageSub?.cancel();
    _connectionStateSub?.cancel();
    _roomStreamController.close();
  }
}
