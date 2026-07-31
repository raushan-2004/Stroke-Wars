import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/replay/domain/models/replay_models.dart';
import 'package:stroke_wars/features/replay/application/replay_player.dart';

/// Plain Dart controller driving playback sessions and timeline controls.
class ReplayController {
  ReplayController({
    required this.matchController,
    required this.canvasController,
    required this.metadata,
    required this.eventLog,
    required this.checkpoints,
    required this.bookmarks,
  }) {
    _player = ReplayPlayer(
      matchController: matchController,
      canvasController: canvasController,
      metadata: metadata,
      eventLog: eventLog,
      checkpoints: checkpoints,
      bookmarks: bookmarks,
      onSessionUpdated: _onSessionUpdated,
    );
  }

  final MatchController matchController;
  final CanvasController canvasController;
  final ReplayMetadata metadata;
  final ReplayEventLog eventLog;
  final List<ReplayCheckpoint> checkpoints;
  final List<Bookmark> bookmarks;

  late final ReplayPlayer _player;
  final List<void Function(ReplaySession)> _listeners = [];

  ReplaySession get session => _player.session;
  List<Map<String, dynamic>> get chatHistory => _player.chatHistory;

  void addListener(void Function(ReplaySession) listener) {
    _listeners.add(listener);
    listener(session);
  }

  void removeListener(void Function(ReplaySession) listener) {
    _listeners.remove(listener);
  }

  void play() {
    _player.play();
  }

  void pause() {
    _player.pause();
  }

  void resume() {
    _player.resume();
  }

  void restart() {
    _player.restart();
  }

  void stepForward() {
    _player.stepForward();
  }

  void stepBackward() {
    _player.stepBackward();
  }

  void seekTo(int targetMs) {
    _player.seekTo(targetMs);
  }

  void setSpeed(double speed) {
    _player.setSpeed(speed);
  }

  void _onSessionUpdated(ReplaySession updatedSession) {
    for (final listener in _listeners) {
      listener(updatedSession);
    }
  }

  void dispose() {
    _player.dispose();
  }
}
