import 'dart:convert';

import 'package:stroke_wars/core/storage/storage_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/practice/application/practice_session_coordinator.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_configuration.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_session.dart';

/// Plain Dart controller driving Practice Mode, delegating orchestration to PracticeSessionCoordinator.
class PracticeModeController {
  /// Creates a [PracticeModeController].
  PracticeModeController({
    required this.storage,
    required this.canvasController,
    required this.drawingBus,
    required this.humanPlayerId,
    required this.humanDisplayName,
    this.clock,
  });

  /// Key-value local storage service.
  final StorageService storage;

  /// Drawing canvas controller.
  final CanvasController canvasController;

  /// Canvas drawing event dispatcher.
  final DrawingEventBus drawingBus;

  /// Unique human player ID.
  final String humanPlayerId;

  /// Display name of human player.
  final String humanDisplayName;

  /// Optional clock provider for testing.
  final ClockProvider? clock;

  PracticeSessionCoordinator? _coordinator;
  PracticeSession? _session;
  final List<void Function(PracticeSession?)> _listeners = [];

  static const String _autosaveKey = 'active_practice_session';

  /// Retrieves the active practice session, or null if none in progress.
  PracticeSession? get session => _session;

  /// Subscribes a listener callback to session updates.
  void addListener(void Function(PracticeSession?) listener) {
    _listeners.add(listener);
    listener(_session);
  }

  /// Unsubscribes a listener callback.
  void removeListener(void Function(PracticeSession?) listener) {
    _listeners.remove(listener);
  }

  /// Begins a new offline practice session.
  Future<void> startPractice(PracticeConfiguration config) async {
    _cleanupCoordinator();
    
    _coordinator = PracticeSessionCoordinator(
      canvasController: canvasController,
      drawingBus: drawingBus,
      humanPlayerId: humanPlayerId,
      humanDisplayName: humanDisplayName,
      configuration: config,
      clock: clock,
      onSessionUpdated: _onSessionUpdated,
      onAutosaveTriggered: _onAutosaveTriggered,
    );

    _session = _coordinator!.session;
    _notifyListeners();

    await _coordinator!.start();
  }

  /// Player word choice submission.
  Future<void> chooseWord(Word word) async {
    final coord = _coordinator;
    if (coord == null) return;
    await coord.chooseWord(word);
  }

  /// Forces the current round drawing time to end.
  Future<void> endRound() async {
    final coord = _coordinator;
    if (coord == null) return;
    await coord.endRound();
  }

  /// Transition state to next round or finish the match.
  Future<void> advanceNextRound() async {
    final coord = _coordinator;
    if (coord == null) return;
    await coord.advanceNextRound();
  }

  /// Pauses drawing and match timers.
  void pausePractice() {
    final coord = _coordinator;
    if (coord == null) return;
    coord.pause();
  }

  /// Resumes active drawing and match timers.
  void resumePractice() {
    final coord = _coordinator;
    if (coord == null) return;
    coord.resume();
  }

  /// Restarts the active practice session configuration from scratch.
  void restartPractice() {
    final coord = _coordinator;
    if (coord == null) return;
    coord.restart();
  }

  /// Quits and discards the active practice session.
  Future<void> quitPractice() async {
    final coord = _coordinator;
    if (coord != null) {
      coord.quit();
    }
    _cleanupCoordinator();
    _session = null;
    _notifyListeners();
    try {
      await storage.delete(_autosaveKey);
    } catch (_) {}
  }

  /// Loads and recovers an auto-saved session if present.
  bool loadSavedSession() {
    try {
      if (!storage.containsKey(_autosaveKey)) return false;
      final dataStr = storage.get<String>(_autosaveKey);
      if (dataStr == null) return false;

      final savedSession = PracticeSession.fromJson(json.decode(dataStr) as Map<String, dynamic>);
      
      _coordinator = PracticeSessionCoordinator(
        canvasController: canvasController,
        drawingBus: drawingBus,
        humanPlayerId: humanPlayerId,
        humanDisplayName: humanDisplayName,
        configuration: savedSession.configuration,
        clock: clock,
        onSessionUpdated: _onSessionUpdated,
        onAutosaveTriggered: _onAutosaveTriggered,
      );

      _coordinator!.restoreSession(savedSession);
      _session = savedSession;
      _notifyListeners();
      return true;
    } catch (_) {
      // Safe recovery
      return false;
    }
  }

  void _onSessionUpdated(PracticeSession updated) {
    _session = updated;
    _notifyListeners();
  }

  void _onAutosaveTriggered(PracticeSession sessionToSave) {
    if (!sessionToSave.configuration.autosaveEnabled) return;
    try {
      storage.put(_autosaveKey, json.encode(sessionToSave.toJson()));
    } catch (_) {
      // Safe recovery - autosave failure does not crash session
    }
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(_session);
    }
  }

  void _cleanupCoordinator() {
    _coordinator?.dispose();
    _coordinator = null;
  }

  /// Releases resources.
  void dispose() {
    _cleanupCoordinator();
    _listeners.clear();
  }
}
