import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/online/application/online_session_controller.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';
import 'package:stroke_wars/features/online_gameplay/application/online_game_coordinator.dart';
import 'package:stroke_wars/features/online_gameplay/domain/models/online_game_session.dart';
import 'package:stroke_wars/features/online_gameplay/application/server_event_dispatcher.dart';

/// Plain Dart controller driving the online gameplay session, routing UI intents to coordinator.
class OnlineGameController {
  OnlineGameController({
    required this.sessionController,
    required this.matchController,
    required this.canvasController,
    required this.transport,
  }) {
    _coordinator = OnlineGameCoordinator(
      sessionController: sessionController,
      matchController: matchController,
      canvasController: canvasController,
      transport: transport,
      onSessionUpdated: _onSessionUpdated,
    );
  }

  final OnlineSessionController sessionController;
  final MatchController matchController;
  final CanvasController canvasController;
  final WebSocketTransport transport;

  late final OnlineGameCoordinator _coordinator;
  final List<void Function(OnlineGameSession)> _listeners = [];

  OnlineGameSession get session => _coordinator.gameState;
  List<OnlineChatMessage> get chatHistory => _coordinator.chatHistory;

  void addListener(void Function(OnlineGameSession) listener) {
    _listeners.add(listener);
    listener(session);
  }

  void removeListener(void Function(OnlineGameSession) listener) {
    _listeners.remove(listener);
  }

  /// Toggles lobby ready state.
  Future<void> toggleReady(bool isReady) async {
    await _coordinator.toggleReady(isReady);
  }

  /// Sends a canvas drawing stroke/point event to the server.
  Future<void> sendCanvasEvent(DrawingEvent event) async {
    await _coordinator.sendCanvasEvent(event);
  }

  /// Submits a gameplay guess to the server.
  Future<void> sendGuess(String guessText) async {
    await _coordinator.sendGuess(guessText);
  }

  /// Chooses a round word from selection.
  Future<void> chooseWord(String wordId) async {
    await _coordinator.chooseWord(wordId);
  }

  void _onSessionUpdated(OnlineGameSession updatedSession) {
    for (final listener in _listeners) {
      listener(updatedSession);
    }
  }

  void dispose() {
    _coordinator.dispose();
  }
}
