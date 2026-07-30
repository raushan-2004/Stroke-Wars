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
import 'package:stroke_wars/features/multiplayer/application/connection_manager.dart';
import 'package:stroke_wars/features/multiplayer/application/protocol_serializer.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_statistics.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_configuration.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';
import 'package:stroke_wars/features/multiplayer/domain/repositories/game_transport.dart';
import 'package:stroke_wars/features/online/application/lobby_service.dart';
import 'package:stroke_wars/features/online/application/online_protocol_service.dart';
import 'package:stroke_wars/features/online/application/online_recovery_manager.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
import 'package:stroke_wars/features/online/domain/repositories/online_auth_service.dart';

/// Coordinator coordinating Authentication, LobbyService, OnlineProtocolService,
/// WebSocketTransport, ConnectionManager, and SynchronizationManager.
class OnlineSessionCoordinator {
  OnlineSessionCoordinator({
    required this.matchController,
    required this.canvasController,
    required this.commandProcessor,
    required this.matchEventBus,
    required this.drawingEventBus,
    required this.onSessionUpdated,
    WebSocketTransport? transport,
    OnlineAuthService? authService,
  }) {
    _transport = transport ?? WebSocketTransport();
    _authService = authService ?? MockOnlineAuthService();
    _protocolService = const OnlineProtocolService();

    _lobbyService = LobbyService(
      transport: _transport,
      protocolService: _protocolService,
    );

    _recoveryManager = OnlineRecoveryManager(
      transport: _transport,
      lobbyService: _lobbyService,
      onRecoveryStateChanged: _onRecoveryStateChanged,
    );

    _connectionManager = ConnectionManager(
      transport: _transport,
      serializer: ProtocolSerializer(),
      sessionId: const SessionId('online-session'),
      localConnectionId: const ConnectionId('client'),
      isHost: false,
    );

    _syncManager = SynchronizationManager(
      matchController: matchController,
      canvasController: canvasController,
      onStateChanged: _onSyncStateChanged,
    );

    _session = OnlineSession.initial();
    _init();
  }

  final MatchController matchController;
  final CanvasController canvasController;
  final MatchCommandProcessor commandProcessor;
  final MatchEventBus matchEventBus;
  final DrawingEventBus drawingEventBus;
  final void Function(OnlineSession) onSessionUpdated;

  late final WebSocketTransport _transport;
  late final OnlineAuthService _authService;
  late final OnlineProtocolService _protocolService;
  late final LobbyService _lobbyService;
  late final OnlineRecoveryManager _recoveryManager;
  late final ConnectionManager _connectionManager;
  late final SynchronizationManager _syncManager;

  OnlineSession _session = OnlineSession.initial();
  OnlineSession get session => _session;

  StreamSubscription<TransportMessage>? _messagesSub;
  StreamSubscription<TransportConnectionState>? _connStateSub;
  StreamSubscription<AuthenticationState>? _authStateSub;
  StreamSubscription<NetworkStatistics>? _statsSub;

  void _init() {
    _messagesSub = _transport.messages.listen(_onTransportMessage);
    _connStateSub = _transport.connectionState.listen(
      _onTransportConnectionChanged,
    );
    _authStateSub = _authService.authState.listen(_onAuthStateChanged);
    _statsSub = _connectionManager.onStatisticsChanged.listen(_onStatsChanged);
  }

  /// Starts online connection and anonymous login.
  Future<void> connect(String address, int port, String name) async {
    _updateSession(
      _session.copyWith(sessionState: OnlineSessionState.connecting),
    );

    try {
      await _transport.connect(address, port);

      // Perform Anonymous auth guest login
      final identity = await _authService.loginAnonymously(name);
      final localPeer = PeerInfo(
        id: PeerId(identity.playerId),
        displayName: identity.displayName,
        address: address,
        port: port,
      );

      _updateSession(
        _session.copyWith(
          sessionId: () => identity.token,
          player: () => localPeer,
          sessionState: OnlineSessionState.connected,
        ),
      );

      // Negotiate Server Capabilities immediately
      _sendAuthPacket(identity.displayName, identity.token);
    } catch (e) {
      AppLogger.instance.error(
        'OnlineSessionCoordinator connection failure: $e',
      );
      _updateSession(
        _session.copyWith(sessionState: OnlineSessionState.disconnected),
      );
    }
  }

  /// Disconnects socket and clears authentication.
  Future<void> disconnect() async {
    await _transport.disconnect();
    await _authService.logout();
    _recoveryManager.reset();
    _updateSession(OnlineSession.initial());
  }

  // --- Lobby operations ---
  Future<void> createLobby({
    required String name,
    required int maxPlayers,
    required bool isPrivate,
    String? privateCode,
  }) async {
    _lobbyService.createLobby(
      name: name,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
      privateCode: privateCode,
    );
  }

  Future<void> joinLobby(String lobbyId, [String? privateCode]) async {
    _lobbyService.joinLobby(lobbyId, privateCode);
  }

  Future<void> leaveLobby() async {
    _lobbyService.leaveLobby();
  }

  Future<void> searchPublicLobbies() async {
    _lobbyService.searchPublicLobbies();
  }

  // --- Event & Message handlers ---
  void _onTransportMessage(TransportMessage msg) {
    final payload = _protocolService.decodeInboundMessage(msg.content);
    final type = payload['type'] as String?;

    if (type == 'auth_response') {
      final caps = ServerCapabilities.fromJson(
        payload['capabilities'] as Map<String, dynamic>? ?? {},
      );
      _updateSession(
        _session.copyWith(
          serverCapabilities: () => caps,
          sessionState: OnlineSessionState.browsing,
        ),
      );
    } else if (type == 'lobby_update') {
      final lobbyJson = payload['lobby'] as Map<String, dynamic>?;
      if (lobbyJson != null) {
        final onlineLobby = OnlineLobby.fromJson(lobbyJson);
        _updateSession(
          _session.copyWith(
            lobby: () => onlineLobby,
            sessionState: OnlineSessionState.lobby,
          ),
        );
      }
    } else if (type == 'lobby_list_response') {
      final list = (payload['lobbies'] as List? ?? [])
          .map((item) => DiscoveredLobby.fromJson(item as Map<String, dynamic>))
          .toList();
      _lobbyService.updateLobbiesList(list);
    } else if (type == 'match_start') {
      _updateSession(
        _session.copyWith(sessionState: OnlineSessionState.waiting),
      );
    }
  }

  void _onTransportConnectionChanged(TransportConnectionState state) {
    NetworkConnectionState netState;
    OnlineSessionState lifeState = _session.sessionState;

    switch (state) {
      case TransportConnectionState.connected:
        netState = NetworkConnectionState.connected;
        break;
      case TransportConnectionState.connecting:
        netState = NetworkConnectionState.connecting;
        break;
      case TransportConnectionState.disconnected:
      case TransportConnectionState.failed:
        netState = NetworkConnectionState.disconnected;
        lifeState = OnlineSessionState.disconnected;
        break;
    }

    _updateSession(
      _session.copyWith(connectionState: netState, sessionState: lifeState),
    );

    // Handle auto-recovery upon disconnection if in a room
    if (state == TransportConnectionState.disconnected &&
        _session.lobby != null) {
      _recoveryManager.initiateRestoration(
        lastSessionId: _session.sessionId,
        lastLobby: _session.lobby,
        address: _session.player?.address ?? '127.0.0.1',
        port: _session.player?.port ?? 18080,
      );
    }
  }

  void _onAuthStateChanged(AuthenticationState state) {
    _updateSession(_session.copyWith(authenticationState: state));
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

  void _onSyncStateChanged(
    SynchronizationState state,
    SynchronizationDiagnostics diag,
  ) {
    _updateSession(_session.copyWith(synchronizationState: state));
  }

  void _onRecoveryStateChanged(bool isRestoring) {
    if (isRestoring) {
      _updateSession(
        _session.copyWith(
          synchronizationState: SynchronizationState.recovering,
        ),
      );
    }
  }

  void _sendAuthPacket(String name, String token) {
    final packet = _protocolService.buildAuthRequest(name, token);
    _transport.send('server', packet);
  }

  void _updateSession(OnlineSession newSession) {
    _session = newSession;
    onSessionUpdated(newSession);
  }

  void dispose() {
    _messagesSub?.cancel();
    _connStateSub?.cancel();
    _authStateSub?.cancel();
    _statsSub?.cancel();
    _transport.dispose();
    _lobbyService.dispose();
  }
}
