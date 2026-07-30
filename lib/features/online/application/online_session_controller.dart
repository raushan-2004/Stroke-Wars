import 'dart:async';

import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/online/application/lobby_service.dart';
import 'package:stroke_wars/features/online/application/online_session_coordinator.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
import 'package:stroke_wars/features/online/domain/repositories/online_auth_service.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';

/// Plain Dart controller driving the Online session lifecycle and routing UI actions.
class OnlineSessionController {
  OnlineSessionController({
    required this.matchController,
    required this.canvasController,
    required this.commandProcessor,
    required this.matchEventBus,
    required this.drawingEventBus,
    WebSocketTransport? transport,
    OnlineAuthService? authService,
  }) {
    _coordinator = OnlineSessionCoordinator(
      matchController: matchController,
      canvasController: canvasController,
      commandProcessor: commandProcessor,
      matchEventBus: matchEventBus,
      drawingEventBus: drawingEventBus,
      onSessionUpdated: _onSessionUpdated,
      transport: transport,
      authService: authService,
    );
  }

  final MatchController matchController;
  final CanvasController canvasController;
  final MatchCommandProcessor commandProcessor;
  final MatchEventBus matchEventBus;
  final DrawingEventBus drawingEventBus;

  late final OnlineSessionCoordinator _coordinator;
  final List<void Function(OnlineSession)> _listeners = [];

  OnlineSession get session => _coordinator.session;

  void addListener(void Function(OnlineSession) listener) {
    _listeners.add(listener);
    listener(session);
  }

  void removeListener(void Function(OnlineSession) listener) {
    _listeners.remove(listener);
  }

  /// Connects to a remote server.
  Future<void> connect({
    required String address,
    required int port,
    required String playerName,
  }) async {
    await _coordinator.connect(address, port, playerName);
  }

  /// Disconnects from current online server.
  Future<void> disconnect() async {
    await _coordinator.disconnect();
  }

  /// Creates a new lobby.
  Future<void> createLobby({
    required String roomName,
    required int maxPlayers,
    required bool isPrivate,
    String? privateCode,
  }) async {
    await _coordinator.createLobby(
      name: roomName,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
      privateCode: privateCode,
    );
  }

  /// Joins an existing lobby.
  Future<void> joinLobby(String lobbyId, [String? privateCode]) async {
    await _coordinator.joinLobby(lobbyId, privateCode);
  }

  /// Leaves the current lobby.
  Future<void> leaveLobby() async {
    await _coordinator.leaveLobby();
  }

  /// Searches for public lobbies.
  Future<void> searchPublicLobbies() async {
    await _coordinator.searchPublicLobbies();
  }

  void _onSessionUpdated(OnlineSession updatedSession) {
    for (final listener in _listeners) {
      listener(updatedSession);
    }
  }

  void dispose() {
    _coordinator.dispose();
  }
}
