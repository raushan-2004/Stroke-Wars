import 'dart:async';
import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/lan/application/synchronization_manager.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/multiplayer/application/client_controller.dart';
import 'package:stroke_wars/features/multiplayer/application/connection_manager.dart';
import 'package:stroke_wars/features/multiplayer/application/host_controller.dart';
import 'package:stroke_wars/features/multiplayer/application/peer_discovery_service.dart';
import 'package:stroke_wars/features/multiplayer/application/protocol_serializer.dart';
import 'package:stroke_wars/features/multiplayer/data/local_network_transport.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_statistics.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_configuration.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';

/// Lightweight coordinator wiring HostController/ClientController,
/// socket lifecycles, and delegating sync steps to SynchronizationManager.
class LANSessionCoordinator {
  LANSessionCoordinator({
    required this.matchController,
    required this.canvasController,
    required this.commandProcessor,
    required this.matchEventBus,
    required this.drawingEventBus,
    required this.onSessionUpdated,
  }) {
    _syncManager = SynchronizationManager(
      matchController: matchController,
      canvasController: canvasController,
      onStateChanged: _onSyncStateChanged,
    );
    _session = LANSession.initial();
    _initDiscovery();
  }

  final MatchController matchController;
  final CanvasController canvasController;
  final MatchCommandProcessor commandProcessor;
  final MatchEventBus matchEventBus;
  final DrawingEventBus drawingEventBus;
  final void Function(LANSession) onSessionUpdated;

  late final SynchronizationManager _syncManager;

  LANSession _session = LANSession.initial();
  PeerDiscoveryService? _discoveryService;
  LocalNetworkTransport? _transport;
  ConnectionManager? _connectionManager;
  HostController? _hostController;
  ClientController? _clientController;

  final List<DiscoveredRoom> _discoveredRooms = [];
  final StreamController<List<DiscoveredRoom>> _discoveredRoomsController =
      StreamController<List<DiscoveredRoom>>.broadcast();

  StreamSubscription? _roomSub;
  StreamSubscription? _connStateSub;
  StreamSubscription? _statsSub;
  StreamSubscription? _discoverySub;
  StreamSubscription? _matchStateSub;

  LANSession get session => _session;
  Stream<List<DiscoveredRoom>> get discoveredRooms =>
      _discoveredRoomsController.stream;

  void _initDiscovery() {
    _discoveryService = PeerDiscoveryService();
    _discoverySub = _discoveryService!.discoveredRooms.listen((rooms) {
      _discoveredRooms.clear();
      _discoveredRooms.addAll(rooms);
      _discoveredRoomsController.add(
        List<DiscoveredRoom>.from(_discoveredRooms),
      );
    });
    _discoveryService!.startBrowsing();
  }

  /// Establishes a host lobby socket and configures HostController.
  Future<void> hostGame({
    required String roomName,
    required String hostName,
    required int maxPlayers,
    int port = 18080,
  }) async {
    await _cleanupActiveSession();
    _syncManager.reset();

    _updateSession(
      _session.copyWith(
        sessionState: LANSessionLifecycleState.joining,
        connectionState: NetworkConnectionState.connecting,
      ),
    );

    try {
      _transport = LocalNetworkTransport(isHost: true);
      await _transport!.connect('0.0.0.0', port);

      final serializer = ProtocolSerializer();
      _connectionManager = ConnectionManager(
        transport: _transport!,
        serializer: serializer,
        sessionId: SessionId(
          'session-${DateTime.now().millisecondsSinceEpoch}',
        ),
        localConnectionId: const ConnectionId('host-conn'),
        isHost: true,
      );

      _hostController = HostController(
        connectionManager: _connectionManager!,
        matchController: matchController,
        canvasController: canvasController,
        commandProcessor: commandProcessor,
        matchEventBus: matchEventBus,
        drawingEventBus: drawingEventBus,
        synchronizationManager: _syncManager,
      );

      final hostInfo = PeerInfo(
        id: const PeerId('host'),
        displayName: hostName,
        address: '127.0.0.1',
        port: port,
      );

      _hostController!.createRoom(
        RoomId('room-${DateTime.now().millisecondsSinceEpoch}'),
        hostInfo,
        RoomConfiguration(
          name: roomName,
          matchConfiguration: MatchConfiguration(maxPlayers: maxPlayers),
        ),
      );

      // Start UDP Broadcast for room discovery
      await _discoveryService!.startAdvertising(
        roomId: _hostController!.room!.id,
        hostName: hostName,
        playerCount: 1,
        maxPlayers: maxPlayers,
        gamePort: port,
        roomState: 'waiting',
      );

      _roomSub = _hostController!.onRoomChanged.listen(_onRoomChanged);
      _connStateSub = _connectionManager!.connectionState.listen(
        _onConnectionStateChanged,
      );
      _statsSub = _connectionManager!.onStatisticsChanged.listen(
        _onStatsChanged,
      );

      // Bind match controller game state listener to sync lifecycle shifts
      _matchStateSub = matchEventBus.stream.listen(
        (_) => _onMatchChanged(matchController.match),
      );

      // Initialize match aggregate authoritatively on host
      matchController.match = Match(
        id: MatchId('match-${DateTime.now().millisecondsSinceEpoch}'),
        hostId: 'host',
        configuration: MatchConfiguration(maxPlayers: maxPlayers),
        players: const [],
        rounds: const [],
        state: const MatchCreatedState(),
        createdAt: DateTime.now(),
      );
      // Join host automatically to the match
      commandProcessor.process(
        JoinMatchCommand(
          matchId: matchController.match!.id,
          playerId: 'host',
          displayName: hostName,
        ),
      );

      _updateSession(
        _session.copyWith(
          room: () => _hostController!.room,
          players: _hostController!.room?.players ?? const [],
          connectionState: NetworkConnectionState.connected,
          connectionQuality: ConnectionQuality.excellent,
          synchronizationState: SynchronizationState.synchronized,
          sessionState: LANSessionLifecycleState.lobby,
          currentMatch: () => matchController.match,
          canvasState: canvasController.state,
        ),
      );
    } catch (e) {
      AppLogger.instance.error('LANSessionCoordinator failed hosting game: $e');
      _updateSession(
        _session.copyWith(
          sessionState: LANSessionLifecycleState.disconnected,
          connectionState: NetworkConnectionState.failed,
        ),
      );
    }
  }

  /// Connects to a remote host socket and configures ClientController mirror.
  Future<void> joinGame({
    required String address,
    required int port,
    required String playerName,
  }) async {
    await _cleanupActiveSession();
    _syncManager.reset();

    _updateSession(
      _session.copyWith(
        sessionState: LANSessionLifecycleState.joining,
        connectionState: NetworkConnectionState.connecting,
      ),
    );

    try {
      _transport = LocalNetworkTransport(isHost: false);
      final serializer = ProtocolSerializer();
      final localPeerId = 'peer-${DateTime.now().millisecondsSinceEpoch}';

      _connectionManager = ConnectionManager(
        transport: _transport!,
        serializer: serializer,
        sessionId: SessionId(
          'session-${DateTime.now().millisecondsSinceEpoch}',
        ),
        localConnectionId: ConnectionId(localPeerId),
        isHost: false,
      );

      _clientController = ClientController(
        connectionManager: _connectionManager!,
        matchController: matchController,
        canvasController: canvasController,
        matchEventBus: matchEventBus,
        synchronizationManager: _syncManager,
      );

      final localPeer = PeerInfo(
        id: PeerId(localPeerId),
        displayName: playerName,
        address: '127.0.0.1',
        port: port + 1, // Port offset
      );

      _roomSub = _clientController!.onRoomChanged.listen(_onRoomChanged);
      _connStateSub = _connectionManager!.connectionState.listen(
        _onConnectionStateChanged,
      );
      _statsSub = _connectionManager!.onStatisticsChanged.listen(
        _onStatsChanged,
      );
      _matchStateSub = matchEventBus.stream.listen(
        (_) => _onMatchChanged(matchController.match),
      );

      await _clientController!.joinRoom(address, port, localPeer);
    } catch (e) {
      AppLogger.instance.error('LANSessionCoordinator failed joining game: $e');
      _updateSession(
        _session.copyWith(
          sessionState: LANSessionLifecycleState.disconnected,
          connectionState: NetworkConnectionState.failed,
        ),
      );
    }
  }

  /// Toggles lobby ready state.
  Future<void> toggleReady(bool isReady) async {
    final connId = _connectionManager?.localConnectionId.value;
    if (connId == null) return;

    if (_hostController != null) {
      _hostController!.handleReadyToggle('host', isReady);
    } else if (_clientController != null) {
      await _connectionManager!.sendPayload(
        ReadyMessage(peerId: connId, isReady: isReady),
      );
    }
  }

  /// Host starts the match gameplay.
  Future<void> startMatch() async {
    if (_hostController == null) return;
    commandProcessor.process(
      StartMatchCommand(matchId: matchController.match!.id, hostId: 'host'),
    );
  }

  /// Sends a canvas drawing event to the host authority.
  void sendDrawingEvent(DrawingEvent event) {
    if (_hostController != null) {
      // Validate drawer ownership locally on host
      final activeDrawerId = matchController.match?.currentRound?.drawerSlotId;
      if (activeDrawerId == 'host') {
        drawingEventBus.publish(event);
      }
    } else if (_clientController != null) {
      final activeDrawerId = matchController.match?.currentRound?.drawerSlotId;
      final localPlayerId = _connectionManager?.localConnectionId.value;
      if (localPlayerId == activeDrawerId) {
        _clientController!.sendCanvasEvent(event);
      }
    }
  }

  /// Sends a match command intent to the host authority.
  void sendMatchCommand(MatchCommand command) {
    if (_hostController != null) {
      commandProcessor.process(command);
    } else if (_clientController != null) {
      _clientController!.sendCommand(command);
    }
  }

  /// Voluntary departure and cleanup of sessions.
  Future<void> leaveRoom() async {
    final playerVal = _connectionManager?.localConnectionId.value ?? 'host';
    if (_hostController != null) {
      await _discoveryService!.stopAdvertising();
      // Inform all clients of room closure
      _connectionManager!.sendPayload(
        LeaveRoomMessage(peerId: 'host', reason: 'Host closed lobby'),
      );
    } else if (_clientController != null) {
      await _clientController!.leaveRoom(playerVal);
    }
    await _cleanupActiveSession();
    _updateSession(
      LANSession.initial().copyWith(
        sessionState: LANSessionLifecycleState.closed,
      ),
    );
  }

  void _onRoomChanged(Room room) {
    _updateSession(_session.copyWith(room: () => room, players: room.players));
  }

  void _onConnectionStateChanged(NetworkConnectionState state) {
    LANSessionLifecycleState lifeState = _session.sessionState;
    if (state == NetworkConnectionState.disconnected) {
      lifeState = LANSessionLifecycleState.disconnected;
    } else if (state == NetworkConnectionState.connected &&
        lifeState == LANSessionLifecycleState.joining) {
      lifeState = LANSessionLifecycleState.lobby;
    }

    _updateSession(
      _session.copyWith(connectionState: state, sessionState: lifeState),
    );
  }

  void _onStatsChanged(NetworkStatistics stats) {
    _syncManager.updateLatency(stats.latencyMs);
    _updateSession(
      _session.copyWith(
        networkStatistics: stats,
        connectionQuality: ConnectionQuality.fromLatency(stats.latencyMs),
      ),
    );
  }

  void _onMatchChanged(Match? match) {
    if (match == null) {
      _updateSession(_session.copyWith(currentMatch: () => null));
      return;
    }

    LANSessionLifecycleState lifeState = _session.sessionState;
    final matchState = match.state;

    if (matchState is MatchWaitingState || matchState is MatchStartingState) {
      lifeState = LANSessionLifecycleState.lobby;
    } else if (matchState is MatchFinishedState ||
        matchState is MatchCancelledState) {
      lifeState = LANSessionLifecycleState.results;
    } else if (matchState.isActive) {
      lifeState = LANSessionLifecycleState.playing;
    }

    _updateSession(
      _session.copyWith(currentMatch: () => match, sessionState: lifeState),
    );
  }

  void _onSyncStateChanged(
    SynchronizationState syncState,
    SynchronizationDiagnostics diagnostics,
  ) {
    _updateSession(
      _session.copyWith(
        synchronizationState: syncState,
        diagnostics: diagnostics,
      ),
    );
  }

  void _updateSession(LANSession newSession) {
    _session = newSession;
    onSessionUpdated(_session);
  }

  Future<void> _cleanupActiveSession() async {
    await _discoveryService!.stopAdvertising();
    await _roomSub?.cancel();
    await _connStateSub?.cancel();
    await _statsSub?.cancel();
    await _matchStateSub?.cancel();
    _roomSub = null;
    _connStateSub = null;
    _statsSub = null;
    _matchStateSub = null;

    _hostController?.dispose();
    _clientController?.dispose();
    _connectionManager?.dispose();
    _transport?.disconnect();

    _hostController = null;
    _clientController = null;
    _connectionManager = null;
    _transport = null;
  }

  void dispose() {
    _cleanupActiveSession();
    _discoveryService?.stopBrowsing();
    _discoverySub?.cancel();
    _discoveredRoomsController.close();
  }
}
