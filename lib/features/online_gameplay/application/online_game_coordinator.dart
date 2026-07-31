import 'dart:async';
import 'dart:convert';

import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/lan/application/synchronization_manager.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_snapshot.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';
import 'package:stroke_wars/features/online/application/online_session_controller.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';
import 'package:stroke_wars/features/online_gameplay/domain/models/online_game_session.dart';
import 'package:stroke_wars/features/online_gameplay/application/server_event_dispatcher.dart';
import 'package:stroke_wars/features/online_gameplay/application/snapshot_applier.dart';

/// Coordinator orchestrating local engines, network overlays, and server packet dispatches.
class OnlineGameCoordinator {
  OnlineGameCoordinator({
    required this.sessionController,
    required this.matchController,
    required this.canvasController,
    required this.transport,
    required this.onSessionUpdated,
  }) {
    _snapshotApplier = SnapshotApplier(
      matchController: matchController,
      canvasController: canvasController,
    );

    _syncManager = SynchronizationManager(
      matchController: matchController,
      canvasController: canvasController,
      onStateChanged: _onSyncStateChanged,
    );

    _dispatcher = ServerEventDispatcher(
      onMatchStateChanged: _handleMatchSnapshot,
      onDrawingEventReceived: _handleDrawingEvent,
      onLobbyUpdated: _handleLobbyUpdate,
      onChatMessageReceived: _handleChatMessage,
      onNotificationReceived: _handleNotification,
    );

    _gameState = OnlineGameSession.initial().copyWith(
      onlineSession: sessionController.session,
    );

    _init();
  }

  final OnlineSessionController sessionController;
  final MatchController matchController;
  final CanvasController canvasController;
  final WebSocketTransport transport;
  final void Function(OnlineGameSession) onSessionUpdated;

  late final SnapshotApplier _snapshotApplier;
  late final SynchronizationManager _syncManager;
  late final ServerEventDispatcher _dispatcher;

  OnlineGameSession _gameState = OnlineGameSession.initial();
  OnlineGameSession get gameState => _gameState;

  StreamSubscription? _transportSub;

  final List<OnlineChatMessage> _chatHistory = [];
  List<OnlineChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  void _init() {
    _transportSub = transport.messages.listen((msg) {
      try {
        final payload = jsonDecode(msg.content) as Map<String, dynamic>;
        _dispatcher.dispatch(payload);
      } catch (_) {}
    });

    sessionController.addListener(_handleOnlineSessionUpdate);
  }

  /// Toggles lobby ready state.
  Future<void> toggleReady(bool isReady) async {
    final packet = jsonEncode({
      'type': 'ready_toggle_request',
      'isReady': isReady,
    });
    await transport.send('server', packet);
  }

  /// Sends a canvas drawing stroke/point event to the server.
  Future<void> sendCanvasEvent(DrawingEvent event) async {
    // Client drawing validation: only active drawer can send coordinates
    final currentDrawerId = matchController.match?.currentRound?.drawerSlotId;
    final localPlayerId = sessionController.session.player?.id.value;

    if (currentDrawerId != localPlayerId) {
      AppLogger.instance.warning(
        'OnlineGameCoordinator: Prevented unauthorized local drawing because player is not the active drawer',
      );
      return; // Block
    }

    final packet = jsonEncode({
      'type': 'drawing_event',
      'event': event.toJson(),
    });
    await transport.send('server', packet);
  }

  /// Submits a gameplay guess to the server.
  Future<void> sendGuess(String guessText) async {
    final packet = jsonEncode({
      'type': 'submit_guess',
      'guessText': guessText,
    });
    await transport.send('server', packet);
  }

  /// Chooses a round word from selection.
  Future<void> chooseWord(String wordId) async {
    final packet = jsonEncode({
      'type': 'choose_word',
      'wordId': wordId,
    });
    await transport.send('server', packet);
  }

  // --- Handlers ---
  void _handleMatchSnapshot(Map<String, dynamic> snapshotJson) {
    try {
      final snapshot = RoomSnapshot.fromJson(snapshotJson);
      final hostId = _gameState.onlineSession.lobby?.hostId ?? 'host';

      final success = _snapshotApplier.applySnapshot(snapshot, hostId);
      if (success) {
        final match = matchController.match;
        _updateState(_gameState.copyWith(
          currentMatch: () => match,
          round: () => match?.currentRound,
          players: match?.players.map((p) => PlayerConnection(
            peerInfo: PeerInfo(
              id: PeerId(p.playerId),
              displayName: p.displayName,
              address: '127.0.0.1',
              port: 0,
            ),
            connectionState: p.isConnected ? NetworkConnectionState.connected : NetworkConnectionState.disconnected,
            isReady: p.isReady,
            lastSeen: DateTime.now(),
          )).toList().cast<PlayerConnection>() ?? const [],
          onlineGameState: _mapMatchState(match?.state),
          currentDrawer: () => match?.currentRound?.drawerSlotId,
        ));
      }
    } catch (e) {
      AppLogger.instance.error('OnlineGameCoordinator: Failed to apply match snapshot: $e');
    }
  }

  void _handleDrawingEvent(DrawingEvent event) {
    _snapshotApplier.applyDrawingEvent(event);
  }

  void _handleLobbyUpdate(OnlineLobby lobby) {
    _updateState(_gameState.copyWith(
      players: lobby.players,
    ));
  }

  void _handleChatMessage(OnlineChatMessage msg) {
    _chatHistory.add(msg);
  }

  void _handleNotification(String text) {
    AppLogger.instance.info('Server Notification: $text');
  }

  void _handleOnlineSessionUpdate(OnlineSession session) {
    final netStats = session.networkStatistics;
    final overlay = _gameState.networkOverlayState.copyWith(
      latency: netStats.latencyMs,
      jitter: netStats.jitterMs,
      packetLoss: netStats.packetsDropped.toDouble(),
      reconnectStatus: session.connectionState == NetworkConnectionState.connected ? 'Connected' : 'Reconnecting',
      synchronizationStatus: session.synchronizationState.name,
    );

    _updateState(_gameState.copyWith(
      onlineSession: session,
      connectionQuality: session.connectionQuality,
      synchronizationState: session.synchronizationState,
      networkOverlayState: overlay,
    ));
  }

  void _onSyncStateChanged(SynchronizationState state, SynchronizationDiagnostics diag) {
    _updateState(_gameState.copyWith(
      synchronizationState: state,
    ));
  }

  OnlineGameState _mapMatchState(MatchState? state) {
    if (state == null) return OnlineGameState.disconnected;
    return switch (state) {
      MatchCreatedState() => OnlineGameState.loading,
      MatchWaitingState() => OnlineGameState.waitingForPlayers,
      MatchStartingState() => OnlineGameState.countdown,
      WordSelectionState() => OnlineGameState.playing,
      DrawingState() => OnlineGameState.playing,
      GuessingState() => OnlineGameState.playing,
      RoundFinishedState() => OnlineGameState.roundEnd,
      ScoreboardState() => OnlineGameState.roundEnd,
      MatchFinishedState() => OnlineGameState.results,
      MatchCancelledState() => OnlineGameState.disconnected,
    };
  }

  void _updateState(OnlineGameSession newState) {
    _gameState = newState;
    onSessionUpdated(newState);
  }

  void dispose() {
    _transportSub?.cancel();
    _syncManager.reset();
    _snapshotApplier.reset();
  }
}
