import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';
import 'package:stroke_wars/features/practice/application/practice_bot_engine.dart';
import 'package:stroke_wars/features/practice/application/practice_mode_controller.dart';
import 'package:stroke_wars/features/practice/application/practice_replay_recorder.dart';
import 'package:stroke_wars/features/practice/application/practice_session_coordinator.dart';
import 'package:stroke_wars/features/practice/application/practice_statistics_collector.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_configuration.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_session.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_statistics.dart';

// Custom mock storage service for testing
class MockStorageService implements StorageService {
  final Map<String, dynamic> _data = {};

  @override
  T? get<T>(String key) => _data[key] as T?;

  @override
  Future<void> put<T>(String key, T value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}

void main() {
  group('Practice Mode Integration (PMI) - Unit & Integration Tests', () {
    late MockStorageService storage;
    late RenderQueue renderQueue;
    late DrawingEventBus drawingBus;
    late DrawingEventDispatcher drawingDispatcher;
    late CanvasController canvasController;
    late TestClock testClock;

    setUp(() {
      storage = MockStorageService();
      renderQueue = RenderQueue();
      drawingBus = DrawingEventBus();
      drawingDispatcher = DrawingEventDispatcher(eventBus: drawingBus);
      canvasController = CanvasController(renderQueue: renderQueue, dispatcher: drawingDispatcher);
      testClock = TestClock(DateTime(2026, 7, 29, 12, 0, 0));
    });

    test('PracticeConfiguration holds default values and JSON serialization', () {
      const config = PracticeConfiguration();
      expect(config.rounds, 3);
      expect(config.botCount, 2);
      expect(config.drawTimeSecs, 60);

      final jsonMap = config.toJson();
      final restored = PracticeConfiguration.fromJson(jsonMap);
      expect(restored.rounds, 3);
      expect(restored.botCount, 2);
    });

    test('PracticeStatisticsCollector tracks drawings, undo/redo, time ticks', () {
      const collector = PracticeStatisticsCollector();
      var stats = const PracticeStatistics();

      // Start stroke
      stats = collector.processDrawingEvent(
        stats,
        StrokeStarted(
          strokeId: 's1',
          playerId: 'human-1',
          brushId: 'classic',
          color: '#ffffff',
          width: 8,
          opacity: 1,
          timestamp: DateTime(2026, 7, 29),
        ),
      );
      expect(stats.strokeCount, 1);
      expect(stats.brushUsage['classic'], 1);

      // Add points
      stats = collector.processDrawingEvent(stats, const PointAdded(strokeId: 's1', point: StrokePoint(x: 0, y: 0, timestamp: 0)));
      stats = collector.processDrawingEvent(stats, const PointAdded(strokeId: 's1', point: StrokePoint(x: 0, y: 0, timestamp: 0)));
      expect(stats.averageStrokeLength, 2.0);

      // Undo/Redo
      stats = collector.processDrawingEvent(stats, const UndoPerformed());
      expect(stats.undoCount, 1);

      stats = collector.processDrawingEvent(stats, const RedoPerformed());
      expect(stats.redoCount, 1);

      // Time ticks
      stats = collector.processTimeTick(stats, 5.0, true); // drawing
      stats = collector.processTimeTick(stats, 10.0, false); // idle
      expect(stats.drawingDuration, 5.0);
      expect(stats.idleDuration, 10.0);

      // Round completion
      stats = collector.processRoundCompletion(stats, 30);
      expect(stats.totalRoundsCompleted, 1);
      expect(stats.averageRoundDuration, 30.0);
    });

    test('PracticeReplayRecorder records MatchEvents and DrawingEvents', () {
      final recorder = PracticeReplayRecorder();
      expect(recorder.records, isEmpty);

      final time = DateTime(2026, 7, 29, 12, 0, 0);
      recorder.recordDrawingEvent(const UndoPerformed(), time);
      expect(recorder.records, hasLength(1));
      expect(recorder.records.first['type'], 'drawing_event');

      final serialized = recorder.serialize();
      expect(serialized, contains('undo_performed'));
    });

    test('PracticeBotEngine generates guess commands correctly', () {
      final engine = PracticeBotEngine(
        bots: const ['bot-1', 'bot-2'],
        targetWord: 'APPLE',
        incorrectWordPool: const ['ORANGE', 'BANANA'],
      );

      // Tick before correct guess target time (e.g. at 1 second)
      final commandsAt1 = engine.tick(1, const MatchId('practice-match'));
      expect(commandsAt1, isNotNull);

      // Force ticking to 45 seconds should trigger correct guesses for both bots
      final commandsAt45 = engine.tick(45, const MatchId('practice-match'));
      final correctGuesses = commandsAt45
          .whereType<SubmitGuessCommand>()
          .where((c) => c.guessText == 'APPLE')
          .toList();
      expect(correctGuesses, isNotEmpty);
    });

    test('PracticeSessionCoordinator handles lifecycle start, choice, timers, and autosave', () async {
      var updatedCount = 0;
      var autosaveCount = 0;
      late PracticeSession latestSession;

      final config = const PracticeConfiguration(
        rounds: 2,
        botCount: 1,
        drawTimeSecs: 40,
        scoreboardTimeSecs: 5,
        autosaveEnabled: true,
      );

      final coordinator = PracticeSessionCoordinator(
        canvasController: canvasController,
        drawingBus: drawingBus,
        humanPlayerId: 'human-1',
        humanDisplayName: 'Bob',
        configuration: config,
        clock: testClock,
        onSessionUpdated: (session) {
          updatedCount++;
          latestSession = session;
        },
        onAutosaveTriggered: (session) {
          autosaveCount++;
        },
      );

      // Start match
      await coordinator.start();
      expect(latestSession.currentMatch.state, isA<WordSelectionState>());
      expect(latestSession.currentRound, isNotNull);
      expect(latestSession.currentRound!.wordOptions, isNotEmpty);

      // Human chooses word
      final chosenWord = latestSession.currentRound!.wordOptions.first;
      await coordinator.chooseWord(chosenWord);

      expect(latestSession.currentMatch.state, isA<DrawingState>());
      expect(latestSession.currentWord!.text, chosenWord.text);

      // End round
      await coordinator.endRound();
      expect(latestSession.currentMatch.state, isA<RoundFinishedState>());
      expect(autosaveCount, greaterThan(0));

      coordinator.dispose();
    });

    test('PracticeModeController pause, resume, and autosave recovery works', () async {
      final controller = PracticeModeController(
        storage: storage,
        canvasController: canvasController,
        drawingBus: drawingBus,
        humanPlayerId: 'human-1',
        humanDisplayName: 'Bob',
        clock: testClock,
      );

      final config = const PracticeConfiguration(
        rounds: 3,
        botCount: 2,
        autosaveEnabled: true,
      );

      // Start
      await controller.startPractice(config);
      expect(controller.session, isNotNull);

      // Pause
      controller.pausePractice();
      expect(controller.session!.practiceStatistics.pauseCount, 1);
      
      // Verify autosave entry exists in storage
      expect(storage.containsKey('active_practice_session'), true);

      // Resume
      controller.resumePractice();

      // Recover session in a new controller
      final controller2 = PracticeModeController(
        storage: storage,
        canvasController: canvasController,
        drawingBus: drawingBus,
        humanPlayerId: 'human-1',
        humanDisplayName: 'Bob',
        clock: testClock,
      );

      final recovered = controller2.loadSavedSession();
      expect(recovered, true);
      expect(controller2.session!.configuration.rounds, 3);

      await controller.quitPractice();
      controller.dispose();
      controller2.dispose();
    });
  });
}
