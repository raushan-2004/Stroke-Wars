import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/lan/application/lan_session_coordinator.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/multiplayer/application/peer_discovery_service.dart';

/// Plain Dart controller driving the LAN session lifecycle and routing UI actions.
class LANSessionController {
  LANSessionController({
    required this.matchController,
    required this.canvasController,
    required this.commandProcessor,
    required this.matchEventBus,
    required this.drawingEventBus,
  }) {
    _coordinator = LANSessionCoordinator(
      matchController: matchController,
      canvasController: canvasController,
      commandProcessor: commandProcessor,
      matchEventBus: matchEventBus,
      drawingEventBus: drawingEventBus,
      onSessionUpdated: _onSessionUpdated,
    );
  }

  final MatchController matchController;
  final CanvasController canvasController;
  final MatchCommandProcessor commandProcessor;
  final MatchEventBus matchEventBus;
  final DrawingEventBus drawingEventBus;

  late final LANSessionCoordinator _coordinator;
  final List<void Function(LANSession)> _listeners = [];

  LANSession get session => _coordinator.session;
  Stream<List<DiscoveredRoom>> get discoveredRooms => _coordinator.discoveredRooms;

  void addListener(void Function(LANSession) listener) {
    _listeners.add(listener);
    listener(session);
  }

  void removeListener(void Function(LANSession) listener) {
    _listeners.remove(listener);
  }

  /// Hosts a new multiplayer room.
  Future<void> hostGame({
    required String roomName,
    required String hostName,
    required int maxPlayers,
    int port = 18080,
  }) async {
    await _coordinator.hostGame(
      roomName: roomName,
      hostName: hostName,
      maxPlayers: maxPlayers,
      port: port,
    );
  }

  /// Joins an existing room on local network.
  Future<void> joinGame({
    required String address,
    required int port,
    required String playerName,
  }) async {
    await _coordinator.joinGame(
      address: address,
      port: port,
      playerName: playerName,
    );
  }

  /// Toggles lobby ready state.
  Future<void> toggleReady(bool isReady) async {
    await _coordinator.toggleReady(isReady);
  }

  /// Starts match countdown (Host only).
  Future<void> startMatch() async {
    await _coordinator.startMatch();
  }

  /// Sends drawing event.
  void sendDrawingEvent(DrawingEvent event) {
    _coordinator.sendDrawingEvent(event);
  }

  /// Submits word guess intent.
  void sendGuess(String guessText, String playerId) {
    final match = session.currentMatch;
    if (match == null) return;

    final cmd = SubmitGuessCommand(
      matchId: match.id,
      playerId: playerId,
      guessText: guessText,
    );
    _coordinator.sendMatchCommand(cmd);
  }

  /// Selects active drawing word.
  void chooseWord(Word word, String playerId) {
    final match = session.currentMatch;
    if (match == null) return;

    final cmd = ChooseWordCommand(
      matchId: match.id,
      drawerId: playerId,
      wordId: word.id,
    );
    _coordinator.sendMatchCommand(cmd);
  }

  /// Leaves room and closes session.
  Future<void> leaveRoom() async {
    await _coordinator.leaveRoom();
  }

  void _onSessionUpdated(LANSession updatedSession) {
    for (final listener in _listeners) {
      listener(updatedSession);
    }
  }

  void dispose() {
    _coordinator.dispose();
  }
}
