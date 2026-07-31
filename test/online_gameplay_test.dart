import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
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
import 'package:stroke_wars/features/match/domain/models/match.dart' as gameplay;
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/player_slot.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/match/domain/models/round_configuration.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_configuration.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_snapshot.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';
import 'package:stroke_wars/features/online/application/online_session_controller.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
import 'package:stroke_wars/features/online/domain/repositories/online_auth_service.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';
import 'package:stroke_wars/features/online_gameplay/application/online_game_controller.dart';
import 'package:stroke_wars/features/online_gameplay/application/online_game_coordinator.dart';
import 'package:stroke_wars/features/online_gameplay/domain/models/online_game_session.dart';
import 'package:stroke_wars/features/online_gameplay/application/snapshot_applier.dart';

void main() {
  group('Online Gameplay Integration (Stage 8) — Integration Tests', () {
    late HttpServer server;
    late MatchController matchController;
    late CanvasController canvasController;
    late MatchCommandProcessor commandProcessor;
    late MatchEventBus matchEventBus;
    late DrawingEventBus drawingEventBus;

    final List<WebSocket> serverSockets = [];
    final List<String> receivedPackets = [];

    setUp(() async {
      receivedPackets.clear();
      serverSockets.clear();

      // Start Mock Server on port 29090
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 29090);
      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          serverSockets.add(socket);
          socket.listen((message) {
            if (message is String) {
              receivedPackets.add(message);
              if (message == 'ping') {
                socket.add('pong');
                return;
              }

              try {
                final map = jsonDecode(message) as Map<String, dynamic>;
                final type = map['type'] as String?;

                if (type == 'auth_request') {
                  socket.add(jsonEncode({
                    'type': 'auth_response',
                    'capabilities': {
                      'protocolVersion': 1,
                      'engineVersion': '1.0.0',
                      'maximumPlayers': 8,
                      'supportedFeatures': [],
                      'compressionSupport': false,
                      'replaySupport': false,
                      'region': 'MOCK-US',
                    }
                  }));
                }
              } catch (_) {}
            }
          });
        }
      });

      // Init local engines
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

    tearDown(() async {
      for (final s in serverSockets) {
        await s.close();
      }
      serverSockets.clear();
      await server.close(force: true);
    });

    test('SnapshotApplier validates and rejects stale snapshots', () {
      final applier = SnapshotApplier(
        matchController: matchController,
        canvasController: canvasController,
      );

      final snap1 = RoomSnapshot(
        snapshotVersion: 1,
        generatedAt: DateTime.now(),
        sequenceNumber: 10,
        matchSequence: 1,
        room: Room(
          id: const RoomId('room-abc'),
          configuration: const RoomConfiguration(
            name: 'Arena',
            matchConfiguration: MatchConfiguration(maxPlayers: 8),
          ),
          state: RoomState.playing,
          host: const PeerInfo(
            id: PeerId('host'),
            displayName: 'Host',
            address: '127.0.0.1',
            port: 18080,
          ),
          players: [],
        ),
        drawingEvents: [],
      );

      final snapStale = RoomSnapshot(
        snapshotVersion: 1,
        generatedAt: DateTime.now(),
        sequenceNumber: 5, // Stale sequence
        matchSequence: 1,
        room: Room(
          id: const RoomId('room-abc'),
          configuration: const RoomConfiguration(
            name: 'Arena',
            matchConfiguration: MatchConfiguration(maxPlayers: 8),
          ),
          state: RoomState.playing,
          host: const PeerInfo(
            id: PeerId('host'),
            displayName: 'Host',
            address: '127.0.0.1',
            port: 18080,
          ),
          players: [],
        ),
        drawingEvents: [],
      );

      final success1 = applier.applySnapshot(snap1, 'host');
      expect(success1, isTrue);

      final successStale = applier.applySnapshot(snapStale, 'host');
      expect(successStale, isFalse);
    });

    test('OnlineGameCoordinator drawer validation rejects guest drawing events local-side', () async {
      final sessionController = OnlineSessionController(
        matchController: matchController,
        canvasController: canvasController,
        commandProcessor: commandProcessor,
        matchEventBus: matchEventBus,
        drawingEventBus: drawingEventBus,
        transport: WebSocketTransport(),
        authService: MockOnlineAuthService(),
      );

      final coordinator = OnlineGameCoordinator(
        sessionController: sessionController,
        matchController: matchController,
        canvasController: canvasController,
        transport: sessionController.transport,
        onSessionUpdated: (_) {},
      );

      await sessionController.connect(address: '127.0.0.1', port: 29090, playerName: 'Guesty');
      await Future.delayed(const Duration(milliseconds: 300));

      // Inject Match status showing Host is drawing
      matchController.match = gameplay.Match(
        id: const MatchId('match-123'),
        hostId: 'host',
        configuration: const MatchConfiguration(),
        players: [],
        rounds: [
          Round(
            id: const RoundId('round-1'),
            matchId: const MatchId('match-123'),
            roundNumber: 1,
            state: const RoundActiveState(),
            drawerSlotId: 'host', // HOST is drawer, NOT Guesty
            configuration: const RoundConfiguration(drawTimeSecs: 60),
            timerState: null,
            guesses: const [],
            scores: const [],
          )
        ],
        state: const DrawingState(),
        createdAt: DateTime.now(),
      );

      // Attempt to send a local drawing event
      final event = StrokeStarted(
        strokeId: 'stroke-1',
        playerId: 'guesty',
        brushId: 'classic',
        color: '#FF0000',
        width: 5.0,
        opacity: 1.0,
        timestamp: DateTime.now(),
      );

      await coordinator.sendCanvasEvent(event);
      await Future.delayed(const Duration(milliseconds: 200));

      // Packet should NOT have been sent to the server socket
      final sentDrawingPacket = receivedPackets.any((p) => p.contains('drawing_event'));
      expect(sentDrawingPacket, isFalse);

      coordinator.dispose();
      sessionController.dispose();
    });

    test('OnlineGameController coordinates lobby triggers, guesses, and transitions', () async {
      final sessionController = OnlineSessionController(
        matchController: matchController,
        canvasController: canvasController,
        commandProcessor: commandProcessor,
        matchEventBus: matchEventBus,
        drawingEventBus: drawingEventBus,
        transport: WebSocketTransport(),
        authService: MockOnlineAuthService(),
      );

      final controller = OnlineGameController(
        sessionController: sessionController,
        matchController: matchController,
        canvasController: canvasController,
        transport: sessionController.transport,
      );

      final states = <OnlineGameSession>[];
      controller.addListener(states.add);

      await sessionController.connect(address: '127.0.0.1', port: 29090, playerName: 'Guesty');
      await Future.delayed(const Duration(milliseconds: 300));

      // Toggle Ready check
      await controller.toggleReady(true);
      await Future.delayed(const Duration(milliseconds: 200));

      final sentReadyPacket = receivedPackets.any((p) => p.contains('ready_toggle_request'));
      expect(sentReadyPacket, isTrue);

      // Guess check
      await controller.sendGuess('Strawberry');
      await Future.delayed(const Duration(milliseconds: 200));

      final sentGuessPacket = receivedPackets.any((p) => p.contains('submit_guess'));
      expect(sentGuessPacket, isTrue);

      controller.dispose();
      sessionController.dispose();
    });
  });
}
