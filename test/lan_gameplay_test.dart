import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
import 'package:stroke_wars/features/lan/application/synchronization_manager.dart';
import 'package:stroke_wars/features/lan/application/lan_session_coordinator.dart';
import 'package:stroke_wars/features/lan/application/lan_session_controller.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/application/match_command_processor.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/match_state_machine.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/sequence_generator.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';

void main() {
  group('LAN Gameplay Integration (Stage 6B) — Unit & Integration Tests', () {
    late MatchController matchController;
    late CanvasController canvasController;
    late MatchCommandProcessor commandProcessor;
    late MatchEventBus matchEventBus;
    late DrawingEventBus drawingEventBus;

    setUp(() {
      final clock = SystemClock();
      matchEventBus = MatchEventBus();
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
        clock: clock,
        sequenceGenerator: SequenceGenerator(),
      );

      commandProcessor = MatchCommandProcessor(
        controller: matchController,
        stateMachine: MatchStateMachine(validator: MatchValidator()),
        clock: clock,
      );

      canvasController = CanvasController(
        renderQueue: RenderQueue(),
        dispatcher: DrawingEventDispatcher(eventBus: drawingEventBus = DrawingEventBus()),
      );
    });

    test('ConnectionQuality calculation matches latency rules', () {
      expect(ConnectionQuality.fromLatency(-5), ConnectionQuality.disconnected);
      expect(ConnectionQuality.fromLatency(0), ConnectionQuality.disconnected);
      expect(ConnectionQuality.fromLatency(30), ConnectionQuality.excellent);
      expect(ConnectionQuality.fromLatency(80), ConnectionQuality.good);
      expect(ConnectionQuality.fromLatency(180), ConnectionQuality.fair);
      expect(ConnectionQuality.fromLatency(350), ConnectionQuality.poor);
    });

    test('SynchronizationManager sequence validation, duplicate filters and out-of-order detection', () {
      final syncStateChanges = <SynchronizationState>[];
      final manager = SynchronizationManager(
        matchController: matchController,
        canvasController: canvasController,
        onStateChanged: (state, diag) {
          syncStateChanges.add(state);
        },
      );

      final envelope1 = NetworkEnvelope(
        messageId: const MessageId('msg-1'),
        sessionId: const SessionId('sess-1'),
        connectionId: const ConnectionId('peer-1'),
        protocolVersion: 1,
        engineVersion: '1.0.0',
        sequenceNumber: 10, // First seen seq
        acknowledgementNumber: 0,
        timestamp: DateTime.now(),
        payloadType: 'ready',
        payload: const ReadyMessage(peerId: 'peer-1', isReady: true).toJson(),
      );

      // Process normal packet
      final ok1 = manager.processInboundEnvelope(
        envelope: envelope1,
        message: const ReadyMessage(peerId: 'peer-1', isReady: true),
        isHost: true,
        activeDrawerId: 'drawer-1',
        roomPlayerIds: ['drawer-1', 'peer-1'],
        connectionIdToPlayerIdMap: {'peer-1': 'peer-1'},
      );
      expect(ok1, isTrue);

      // Process duplicate sequence packet (seq <= 10)
      final envelopeDuplicate = NetworkEnvelope(
        messageId: const MessageId('msg-2'),
        sessionId: const SessionId('sess-1'),
        connectionId: const ConnectionId('peer-1'),
        protocolVersion: 1,
        engineVersion: '1.0.0',
        sequenceNumber: 9,
        acknowledgementNumber: 0,
        timestamp: DateTime.now(),
        payloadType: 'ready',
        payload: const ReadyMessage(peerId: 'peer-1', isReady: true).toJson(),
      );
      final okDup = manager.processInboundEnvelope(
        envelope: envelopeDuplicate,
        message: const ReadyMessage(peerId: 'peer-1', isReady: true),
        isHost: true,
        activeDrawerId: 'drawer-1',
        roomPlayerIds: ['drawer-1', 'peer-1'],
        connectionIdToPlayerIdMap: {'peer-1': 'peer-1'},
      );
      expect(okDup, isFalse); // Dropped duplicate

      // Process out-of-order sequence packet (seq <= 10)
      final envelopeOutOfOrder = NetworkEnvelope(
        messageId: const MessageId('msg-3'),
        sessionId: const SessionId('sess-1'),
        connectionId: const ConnectionId('peer-1'),
        protocolVersion: 1,
        engineVersion: '1.0.0',
        sequenceNumber: 10,
        acknowledgementNumber: 0,
        timestamp: DateTime.now(),
        payloadType: 'ready',
        payload: const ReadyMessage(peerId: 'peer-1', isReady: true).toJson(),
      );
      final okOOO = manager.processInboundEnvelope(
        envelope: envelopeOutOfOrder,
        message: const ReadyMessage(peerId: 'peer-1', isReady: true),
        isHost: true,
        activeDrawerId: 'drawer-1',
        roomPlayerIds: ['drawer-1', 'peer-1'],
        connectionIdToPlayerIdMap: {'peer-1': 'peer-1'},
      );
      expect(okOOO, isFalse); // Dropped stale out-of-order
    });

    test('SynchronizationManager rejects unauthorised non-drawer Canvas events host-side', () {
      final manager = SynchronizationManager(
        matchController: matchController,
        canvasController: canvasController,
        onStateChanged: (_, __) {},
      );

      final envelopeDrawing = NetworkEnvelope(
        messageId: const MessageId('msg-draw'),
        sessionId: const SessionId('sess-1'),
        connectionId: const ConnectionId('guesser-conn'),
        protocolVersion: 1,
        engineVersion: '1.0.0',
        sequenceNumber: 12,
        acknowledgementNumber: 0,
        timestamp: DateTime.now(),
        payloadType: 'canvas_event',
        payload: CanvasCleared().toJson(),
      );

      // Verify Host rejects because sender is 'guesser-conn' and activeDrawerId is 'drawer-conn'
      final allowed = manager.processInboundEnvelope(
        envelope: envelopeDrawing,
        message: CanvasEventMessage(event: const CanvasCleared()),
        isHost: true,
        activeDrawerId: 'drawer-conn',
        roomPlayerIds: ['drawer-conn', 'guesser-conn'],
        connectionIdToPlayerIdMap: {
          'guesser-conn': 'guesser-conn',
          'drawer-conn': 'drawer-conn',
        },
      );
      expect(allowed, isFalse);

      // Verify Host accepts if sender matches active drawer
      final envelopeDrawingDrawer = NetworkEnvelope(
        messageId: const MessageId('msg-draw-drawer'),
        sessionId: const SessionId('sess-1'),
        connectionId: const ConnectionId('drawer-conn'),
        protocolVersion: 1,
        engineVersion: '1.0.0',
        sequenceNumber: 13,
        acknowledgementNumber: 0,
        timestamp: DateTime.now(),
        payloadType: 'canvas_event',
        payload: CanvasCleared().toJson(),
      );
      final allowedDrawer = manager.processInboundEnvelope(
        envelope: envelopeDrawingDrawer,
        message: CanvasEventMessage(event: const CanvasCleared()),
        isHost: true,
        activeDrawerId: 'drawer-conn',
        roomPlayerIds: ['drawer-conn', 'guesser-conn'],
        connectionIdToPlayerIdMap: {
          'guesser-conn': 'guesser-conn',
          'drawer-conn': 'drawer-conn',
        },
      );
      expect(allowedDrawer, isTrue);
    });

    test('LANSessionCoordinator updates lifecycle states during Host and Join runs', () async {
      final sessions = <LANSession>[];
      final coordinator = LANSessionCoordinator(
        matchController: matchController,
        canvasController: canvasController,
        commandProcessor: commandProcessor,
        matchEventBus: matchEventBus,
        drawingEventBus: drawingEventBus,
        onSessionUpdated: (session) {
          sessions.add(session);
        },
      );

      expect(coordinator.session.sessionState, LANSessionLifecycleState.discovering);

      // Host Game
      await coordinator.hostGame(
        roomName: 'LGI Test Room',
        hostName: 'Alice',
        maxPlayers: 4,
        port: 19090, // Separate port
      );

      expect(coordinator.session.sessionState, LANSessionLifecycleState.lobby);
      expect(coordinator.session.players.length, 1);
      expect(coordinator.session.room!.configuration.name, 'LGI Test Room');

      // Ready Toggle
      await coordinator.toggleReady(true);
      expect(coordinator.session.players.first.isReady, isTrue);

      // Clean up
      await coordinator.leaveRoom();
      expect(coordinator.session.sessionState, LANSessionLifecycleState.closed);
      coordinator.dispose();
    });
  });
}
