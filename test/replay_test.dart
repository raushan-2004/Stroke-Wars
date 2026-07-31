import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/sequence_generator.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart'
    as gameplay;
import 'package:stroke_wars/features/replay/domain/models/replay_models.dart';
import 'package:stroke_wars/features/replay/application/replay_serializer.dart';
import 'package:stroke_wars/features/replay/application/match_event_recorder.dart';
import 'package:stroke_wars/features/replay/application/replay_player.dart';

void main() {
  group('Replay & Match History System (Stage 9) — Integration Tests', () {
    late MatchController matchController;
    late CanvasController canvasController;
    late MatchEventBus matchEventBus;
    late DrawingEventBus drawingEventBus;
    late ReplaySerializer serializer;

    setUp(() {
      matchEventBus = MatchEventBus();
      drawingEventBus = DrawingEventBus();
      serializer = ReplaySerializer();

      matchController = MatchController(
        dispatcher: MatchEventDispatcher(bus: matchEventBus),
        validator: MatchValidator(),
        rules: RuleEngine(
          wordRules: const WordRules(),
          victoryRules: const VictoryRules(),
          configurationRules: const ConfigurationRules(),
        ),
        scoring: const ScoringEngine(),
        wordSelector: WordSelector(
          repository: const DefaultWordList(),
          random: DefaultRandomProvider(),
        ),
        clock: SystemClock(),
        sequenceGenerator: SequenceGenerator(),
      );

      canvasController = CanvasController(
        renderQueue: RenderQueue(),
        dispatcher: DrawingEventDispatcher(eventBus: drawingEventBus),
      );
    });

    test(
      'ReplaySerializer round-trip encoding, checksum validation, version check',
      () {
        final meta = ReplayMetadata(
          matchStartTime: DateTime.now(),
          matchEndTime: DateTime.now().add(const Duration(minutes: 1)),
          duration: const Duration(minutes: 1),
          winner: 'Alice',
          finalScores: {'alice': 350, 'bob': 100},
          playerList: ['Alice', 'Bob'],
          gameMode: 'lan',
          integrity: const ReplayIntegrity(
            replayVersion: 1,
            engineVersion: '1.0.0',
            protocolVersion: 1,
            checksum: '',
          ),
        );

        final log = ReplayEventLog(
          events: [
            ReplayEvent(
              sequenceNumber: 1,
              timestampOffsetMs: 500,
              type: 'match',
              payload: {
                'type': 'timer_tick',
                'matchId': 'match-1',
                'timestamp': DateTime.now().toIso8601String(),
                'roundId': 'r-1',
                'sequenceNumber': 1,
                'remainingSecs': 59,
              },
            ),
          ],
        );

        final checkpoint = ReplayCheckpoint(
          sequenceNumber: 1,
          timestampOffsetMs: 500,
          matchStateJson: {},
          drawingEventsJson: const [],
          scoreboard: const {'alice': 0},
          roundNumber: 1,
        );

        final bookmark = Bookmark(
          title: 'Round Start',
          timestampOffsetMs: 500,
          description: 'Round 1 started',
        );

        final encoded = serializer.encodeReplay(
          metadata: meta,
          eventLog: log,
          checkpoints: [checkpoint],
          bookmarks: [bookmark],
        );

        expect(encoded, isNotEmpty);

        // Successful decode
        final decoded = serializer.decodeReplay(encoded);
        final decodedMeta = decoded['metadata'] as ReplayMetadata;
        expect(decodedMeta.winner, equals('Alice'));
        expect((decoded['eventLog'] as ReplayEventLog).events, hasLength(1));

        // Mismatch check
        final tampered = encoded.replaceAll('timer_tick', 'timer_tock');
        expect(
          () => serializer.decodeReplay(tampered),
          throwsA(isA<FormatException>()),
        );

        // Incompatible version check
        final incompatibleMeta = ReplayMetadata(
          matchStartTime: DateTime.now(),
          matchEndTime: DateTime.now(),
          duration: Duration.zero,
          winner: 'Alice',
          finalScores: const {},
          playerList: const [],
          gameMode: 'lan',
          integrity: const ReplayIntegrity(
            replayVersion: 99, // Unacceptable version
            engineVersion: '1.0.0',
            protocolVersion: 1,
            checksum: '',
          ),
        );
        final incompatibleEncoded = serializer.encodeReplay(
          metadata: incompatibleMeta,
          eventLog: log,
          checkpoints: const [],
          bookmarks: const [],
        );
        expect(
          () => serializer.decodeReplay(incompatibleEncoded),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'MatchEventRecorder passive tracking, automatic bookmarking, checkpoints generation',
      () async {
        final recorder = MatchEventRecorder(
          matchController: matchController,
          canvasController: canvasController,
          matchEventBus: matchEventBus,
          drawingEventBus: drawingEventBus,
        );

        recorder.start();
        expect(recorder.isRecording, isTrue);

        // Set match state to allow checkpointing
        matchController.match = gameplay.Match(
          id: const MatchId('match-123'),
          hostId: 'alice',
          configuration: const MatchConfiguration(),
          players: const [],
          rounds: const [],
          state: const DrawingState(),
          createdAt: DateTime.now(),
        );

        // Trigger MatchEvent
        matchEventBus.publish(
          RoundStartedEvent(
            matchId: const MatchId('match-123'),
            timestamp: DateTime.now(),
            sequenceNumber: 1,
            roundNumber: 1,
            drawerId: 'alice',
          ),
        );

        // Trigger DrawingEvent
        drawingEventBus.publish(const CanvasCleared());

        recorder.recordChatMessage('Alice', 'Hello Replay!');

        await Future<void>.delayed(const Duration(milliseconds: 200));

        recorder.stop();
        expect(recorder.isRecording, isFalse);
      },
    );

    test(
      'ReplayPlayer drives controllers, handles seeking from nearest checkpoint, frame steps',
      () {
        final meta = ReplayMetadata(
          matchStartTime: DateTime.now(),
          matchEndTime: DateTime.now().add(const Duration(seconds: 10)),
          duration: const Duration(seconds: 10),
          winner: 'Host',
          finalScores: const {},
          playerList: const ['Host'],
          gameMode: 'offline',
          integrity: const ReplayIntegrity(
            replayVersion: 1,
            engineVersion: '1.0.0',
            protocolVersion: 1,
            checksum: '',
          ),
        );

        // Initial mock match
        final mockMatch = gameplay.Match(
          id: const MatchId('match-123'),
          hostId: 'host',
          configuration: const MatchConfiguration(),
          players: const [],
          rounds: const [],
          state: const DrawingState(),
          createdAt: DateTime.now(),
        );

        final checkpoint = ReplayCheckpoint(
          sequenceNumber: 1,
          timestampOffsetMs: 2000,
          matchStateJson: mockMatch.toJson(),
          drawingEventsJson: const [],
          scoreboard: const {},
          roundNumber: 1,
        );

        final log = ReplayEventLog(
          events: [
            ReplayEvent(
              sequenceNumber: 2,
              timestampOffsetMs: 3000,
              type: 'match',
              payload: {
                'type': 'timer_tick',
                'matchId': 'match-123',
                'timestamp': DateTime.now().toIso8601String(),
                'roundId': 'r-1',
                'sequenceNumber': 2,
                'remainingSecs': 45,
              },
            ),
          ],
        );

        final player = ReplayPlayer(
          matchController: matchController,
          canvasController: canvasController,
          metadata: meta,
          eventLog: log,
          checkpoints: [checkpoint],
          bookmarks: const [],
          onSessionUpdated: (_) {},
        );

        // Play and seek tests
        player.play();
        expect(player.session.playbackState, equals(PlaybackState.playing));

        player.pause();
        expect(player.session.playbackState, equals(PlaybackState.paused));

        // Seek to 3000ms: should load checkpoint 2000ms and apply event 3000ms
        player.seekTo(3000);
        expect(player.session.currentFrame, equals(3000));
        expect(matchController.match, isNotNull);

        // Speed selection
        player.setSpeed(2.0);
        expect(player.session.playbackSpeed, equals(2.0));

        // Frame stepping
        player.stepForward();
        expect(player.session.currentFrame, equals(3100));

        player.stepBackward();
        expect(player.session.currentFrame, equals(3000));

        player.dispose();
      },
    );
  });
}
