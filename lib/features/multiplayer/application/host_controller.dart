import 'dart:async';
import 'dart:ui';

import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/lan/application/synchronization_manager.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_snapshot.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/multiplayer/application/connection_manager.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_configuration.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_snapshot.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';

/// Authoritative host-side plain Dart controller.
///
/// Directs room entries/kicks, forwards client gameplay command intents,
/// handles UDP heartbeats/timeouts, and broadcasts synchronized event snapshots.
class HostController {
  HostController({
    required this.connectionManager,
    required this.matchController,
    required this.canvasController,
    required this.commandProcessor,
    required this.matchEventBus,
    required this.drawingEventBus,
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
  final MatchCommandProcessor commandProcessor;
  final MatchEventBus matchEventBus;
  final DrawingEventBus drawingEventBus;
  final SynchronizationManager synchronizationManager;

  Room? _room;
  final StreamController<Room> _roomStreamController =
      StreamController<Room>.broadcast();

  StreamSubscription<NetworkEnvelope>? _inboundMessageSub;
  StreamSubscription<String>? _peerTimeoutSub;
  StreamSubscription<MatchEvent>? _matchEventSub;
  StreamSubscription<DrawingEvent>? _drawingEventSub;

  Room? get room => _room;
  Stream<Room> get onRoomChanged => _roomStreamController.stream;

  void _init() {
    _inboundMessageSub = connectionManager.inboundMessages.listen(
      _handleInboundMessage,
    );
    _peerTimeoutSub = connectionManager.onPeerTimeout.listen(
      _handlePeerTimeout,
    );

    // Event pipeline: Listen to local match events and broadcast them to clients
    _matchEventSub = matchEventBus.stream.listen((event) {
      connectionManager.sendPayload(MatchEventMessage(event: event));
      _broadcastRoomSnapshot();
    });

    // Event pipeline: Listen to local drawing events and broadcast them to clients
    _drawingEventSub = drawingEventBus.stream.listen((event) {
      connectionManager.sendPayload(CanvasEventMessage(event: event));
    });
  }

  /// Creates and opens a new multiplayer room.
  void createRoom(RoomId id, PeerInfo hostInfo, RoomConfiguration config) {
    _room = Room(
      id: id,
      configuration: config,
      state: RoomState.waiting,
      host: hostInfo,
      players: [
        PlayerConnection(
          peerInfo: hostInfo,
          connectionState: NetworkConnectionState.connected,
          isReady: true,
          lastSeen: DateTime.now(),
        ),
      ],
    );
    _roomStreamController.add(_room!);
    AppLogger.instance.info(
      'Room ${id.value} created by host: ${hostInfo.displayName}',
    );
  }

  void _handleInboundMessage(NetworkEnvelope envelope) {
    try {
      final msg = connectionManager.serializer.decodePayload(envelope);
      final String senderId = envelope.connectionId.value;

      // Construct connection to player mapping
      final connectionIdToPlayerIdMap = <String, String>{};
      if (_room != null) {
        for (final p in _room!.players) {
          connectionIdToPlayerIdMap[p.peerInfo.id.value] = p.peerInfo.id.value;
          connectionIdToPlayerIdMap[p.peerInfo.address] = p.peerInfo.id.value;
          final hostPortAddress = '${p.peerInfo.address}:${p.peerInfo.port}';
          connectionIdToPlayerIdMap[hostPortAddress] = p.peerInfo.id.value;
        }
      }

      // Delegate sequence, duplicate, and drawer validations to SynchronizationManager
      final allowed = synchronizationManager.processInboundEnvelope(
        envelope: envelope,
        message: msg,
        isHost: true,
        activeDrawerId: matchController.match?.currentRound?.drawerSlotId,
        roomPlayerIds:
            _room?.players.map((p) => p.peerInfo.id.value).toList() ?? const [],
        connectionIdToPlayerIdMap: connectionIdToPlayerIdMap,
      );

      if (!allowed) return;

      if (msg is JoinRoomMessage) {
        _handleJoinRoom(senderId, msg.peerInfo);
      } else if (msg is LeaveRoomMessage) {
        _handleLeaveRoom(senderId);
      } else if (msg is ReadyMessage) {
        _handleReadyToggle(senderId, msg.isReady);
      } else if (msg is MatchCommandMessage) {
        // Forward client commands to the authoritative MatchCommandProcessor
        commandProcessor.process(msg.command);
      } else if (msg is CanvasEventMessage) {
        // Apply drawing command to local CanvasController
        _applyDrawingEventToHost(msg.event);
      }
    } catch (e) {
      AppLogger.instance.error(
        'HostController error handling inbound message: $e',
      );
    }
  }

  void _handleJoinRoom(String connectionId, PeerInfo peer) {
    if (_room == null) return;

    // Check if room is full
    if (_room!.players.length >= _room!.configuration.maxPlayers) {
      connectionManager.sendPayload(
        const ErrorMessage(code: 'ROOM_FULL', message: 'The room is full'),
        targetPeerId: connectionId,
      );
      return;
    }

    // Check if player already in lobby
    if (_room!.players.any((p) => p.peerInfo.id == peer.id)) {
      connectionManager.sendPayload(
        const ErrorMessage(
          code: 'ALREADY_JOINED',
          message: 'Player has already joined this room',
        ),
        targetPeerId: connectionId,
      );
      return;
    }

    final newPlayer = PlayerConnection(
      peerInfo: peer,
      connectionState: NetworkConnectionState.connected,
      isReady: false,
      lastSeen: DateTime.now(),
    );

    final updatedPlayers = List<PlayerConnection>.from(_room!.players)
      ..add(newPlayer);
    _room = _room!.copyWith(players: updatedPlayers);
    _roomStreamController.add(_room!);

    AppLogger.instance.info('Player ${peer.displayName} joined lobby');

    // Notify local match engine if loaded
    if (matchController.match != null) {
      final cmd = JoinMatchCommand(
        matchId: matchController.match!.id,
        playerId: peer.id.value,
        displayName: peer.displayName,
      );
      commandProcessor.process(cmd);
    }

    // Send complete RoomSnapshot to the new client
    _sendSnapshotTo(connectionId);
  }

  void _handleLeaveRoom(String connectionId) {
    if (_room == null) return;

    final index = _room!.players.indexWhere(
      (p) =>
          p.peerInfo.id.value == connectionId ||
          p.peerInfo.address == connectionId.split(':').first,
    );
    if (index == -1) return;

    final leavingPeer = _room!.players[index];
    final updatedPlayers = List<PlayerConnection>.from(_room!.players)
      ..removeAt(index);
    _room = _room!.copyWith(players: updatedPlayers);
    _roomStreamController.add(_room!);

    AppLogger.instance.info(
      'Player ${leavingPeer.peerInfo.displayName} left lobby',
    );

    // Notify match engine
    if (matchController.match != null) {
      final cmd = LeaveMatchCommand(
        matchId: matchController.match!.id,
        playerId: leavingPeer.peerInfo.id.value,
      );
      commandProcessor.process(cmd);
    }

    // Broadcast update
    _broadcastRoomSnapshot();
  }

  void handleReadyToggle(String connectionId, bool isReady) {
    _handleReadyToggle(connectionId, isReady);
  }

  void _handleReadyToggle(String connectionId, bool isReady) {
    if (_room == null) return;

    final updatedPlayers = _room!.players.map((p) {
      if (p.peerInfo.id.value == connectionId ||
          p.peerInfo.address == connectionId.split(':').first) {
        return p.copyWith(isReady: isReady);
      }
      return p;
    }).toList();

    _room = _room!.copyWith(players: updatedPlayers);
    _roomStreamController.add(_room!);

    // Forward ready toggle command to Match engine if active
    if (matchController.match != null) {
      final player = _room!.players.firstWhere(
        (p) =>
            p.peerInfo.id.value == connectionId ||
            p.peerInfo.address == connectionId.split(':').first,
      );
      final cmd = ReadyPlayerCommand(
        matchId: matchController.match!.id,
        playerId: player.peerInfo.id.value,
        isReady: isReady,
      );
      commandProcessor.process(cmd);
    }
  }

  void _handlePeerTimeout(String connId) {
    _handleLeaveRoom(connId);
  }

  void _applyDrawingEventToHost(DrawingEvent event) {
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

  void _broadcastRoomSnapshot() {
    if (_room == null) return;
    final snap = _generateSnapshot();
    connectionManager.sendPayload(SnapshotMessage(snapshot: snap));
  }

  void _sendSnapshotTo(String connectionId) {
    final snap = _generateSnapshot();
    connectionManager.sendPayload(
      SnapshotMessage(snapshot: snap),
      targetPeerId: connectionId,
    );
  }

  RoomSnapshot _generateSnapshot() {
    final matchSnap = matchController.takeSnapshot();
    return RoomSnapshot(
      snapshotVersion: 1,
      generatedAt: DateTime.now(),
      sequenceNumber: connectionManager.statistics.packetsSent,
      matchSequence: matchController.sequenceGenerator.current,
      room: _room!,
      matchSnapshot: matchSnap,
      drawingEvents: canvasController.events,
    );
  }

  void dispose() {
    _inboundMessageSub?.cancel();
    _peerTimeoutSub?.cancel();
    _matchEventSub?.cancel();
    _drawingEventSub?.cancel();
    _roomStreamController.close();
  }
}
