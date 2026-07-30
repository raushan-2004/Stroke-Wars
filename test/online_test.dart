import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
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
import 'package:stroke_wars/features/multiplayer/application/connection_manager.dart';
import 'package:stroke_wars/features/multiplayer/application/protocol_serializer.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';
import 'package:stroke_wars/features/multiplayer/domain/repositories/game_transport.dart';
import 'package:stroke_wars/features/online/application/lobby_service.dart';
import 'package:stroke_wars/features/online/application/online_protocol_service.dart';
import 'package:stroke_wars/features/online/application/online_recovery_manager.dart';
import 'package:stroke_wars/features/online/application/online_session_controller.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
import 'package:stroke_wars/features/online/domain/repositories/online_auth_service.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';

void main() {
  group('Online Multiplayer Foundation (Stage 7) — Integration Tests', () {
    late HttpServer server;
    late MatchController matchController;
    late CanvasController canvasController;
    late MatchCommandProcessor commandProcessor;
    late MatchEventBus matchEventBus;
    late DrawingEventBus drawingEventBus;

    final List<WebSocket> serverSockets = [];

    setUp(() async {
      // Start in-memory mock WebSocket Server
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 28080);
      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          serverSockets.add(socket);
          socket.listen((message) {
            if (message is String) {
              if (message == 'ping') {
                socket.add('pong');
                return;
              }

              try {
                final map = jsonDecode(message) as Map<String, dynamic>;
                final type = map['type'] as String?;

                if (type == 'auth_request') {
                  final token = map['token'] as String;
                  if (token.contains('mismatch')) {
                    socket.add(
                      jsonEncode({
                        'type': 'auth_response',
                        'capabilities': {
                          'protocolVersion': 99, // mismatch
                          'engineVersion': '0.0.1',
                          'maximumPlayers': 2,
                          'supportedFeatures': [],
                          'compressionSupport': false,
                          'replaySupport': false,
                          'region': 'MOCK-LAND',
                        },
                      }),
                    );
                  } else {
                    socket.add(
                      jsonEncode({
                        'type': 'auth_response',
                        'capabilities': {
                          'protocolVersion': 1,
                          'engineVersion': '1.0.0',
                          'maximumPlayers': 8,
                          'supportedFeatures': ['features'],
                          'compressionSupport': true,
                          'replaySupport': true,
                          'region': 'MOCK-EAST',
                        },
                      }),
                    );
                  }
                } else if (type == 'create_lobby_request') {
                  socket.add(
                    jsonEncode({
                      'type': 'lobby_update',
                      'lobby': {
                        'id': 'lobby-abc',
                        'name': map['name'],
                        'hostId': 'guest-id',
                        'players': [
                          {
                            'peerInfo': {
                              'id': 'guest-id',
                              'displayName': 'Guest Player',
                              'address': '127.0.0.1',
                              'port': 28080,
                            },
                            'isReady': false,
                            'connectionState': 'connected',
                            'lastSeen': DateTime.now().toIso8601String(),
                          },
                        ],
                        'isPrivate': map['isPrivate'],
                        'privateCode': map['privateCode'],
                        'maxPlayers': map['maxPlayers'],
                        'metadata': {},
                      },
                    }),
                  );
                } else if (type == 'join_lobby_request') {
                  final id = map['lobbyId'] as String;
                  if (id == 'list_all') {
                    socket.add(
                      jsonEncode({
                        'type': 'lobby_list_response',
                        'lobbies': [
                          {
                            'lobbyId': 'lobby-abc',
                            'name': 'Active Mock Arena',
                            'hostName': 'Host Guy',
                            'playerCount': 2,
                            'maxPlayers': 8,
                            'isPrivate': false,
                          },
                        ],
                      }),
                    );
                  }
                }
              } catch (_) {}
            }
          });
        }
      });

      // Prepare controllers
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
        dispatcher: DrawingEventDispatcher(
          eventBus: drawingEventBus = DrawingEventBus(),
        ),
      );
    });

    tearDown(() async {
      for (final s in serverSockets) {
        await s.close();
      }
      serverSockets.clear();
      await server.close(force: true);
    });

    test(
      'WebSocketTransport connection, heartbeats and cleanup work',
      () async {
        final transport = WebSocketTransport(
          pingInterval: const Duration(milliseconds: 300),
          pongTimeout: const Duration(milliseconds: 200),
        );

        final states = <TransportConnectionState>[];
        transport.connectionState.listen(states.add);

        await transport.connect('127.0.0.1', 28080);
        await Future.delayed(const Duration(milliseconds: 500));

        expect(transport.currentState, TransportConnectionState.connected);

        await transport.disconnect();
        expect(transport.currentState, TransportConnectionState.disconnected);
      },
    );

    test(
      'WebSocketTransport message buffering and overflow discards oldest (FIFO)',
      () async {
        final transport = WebSocketTransport(
          maxQueueSize: 3,
          messageExpiry: const Duration(seconds: 1),
        );

        // Send messages while disconnected
        await transport.send('server', 'msg1');
        await transport.send('server', 'msg2');
        await transport.send('server', 'msg3');
        await transport.send(
          'server',
          'msg4',
        ); // Overflow oldest (msg1 should be dropped)

        // Connect socket
        await transport.connect('127.0.0.1', 28080);
        await Future.delayed(const Duration(milliseconds: 300));

        // Disconnect
        await transport.disconnect();
      },
    );

    test('OnlineProtocolService version validation check', () {
      const service = OnlineProtocolService(
        currentProtocolVersion: 2,
        currentEngineVersion: '2.1.0',
      );
      expect(service.validateCompatibility(2, '2.1.5'), isTrue);
      expect(service.validateCompatibility(1, '2.1.0'), isFalse);
      expect(service.validateCompatibility(2, '1.9.0'), isFalse);
    });

    test(
      'LobbyService create, join, search actions transmit correctly',
      () async {
        final transport = WebSocketTransport();
        await transport.connect('127.0.0.1', 28080);

        final lobbyService = LobbyService(
          transport: transport,
          protocolService: const OnlineProtocolService(),
        );

        // Verify search
        await lobbyService.searchPublicLobbies();
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify create
        await lobbyService.createLobby(
          name: 'Integration Arena',
          maxPlayers: 6,
          isPrivate: false,
        );
        await Future.delayed(const Duration(milliseconds: 200));

        await transport.disconnect();
        lobbyService.dispose();
      },
    );

    test(
      'OnlineSessionController drives authentications and lobbies end-to-end',
      () async {
        final controller = OnlineSessionController(
          matchController: matchController,
          canvasController: canvasController,
          commandProcessor: commandProcessor,
          matchEventBus: matchEventBus,
          drawingEventBus: drawingEventBus,
          transport: WebSocketTransport(),
          authService: MockOnlineAuthService(),
        );

        final sessions = <OnlineSession>[];
        controller.addListener(sessions.add);

        expect(
          controller.session.sessionState,
          OnlineSessionState.disconnected,
        );

        // Connect and Anonymous Auth login
        await controller.connect(
          address: '127.0.0.1',
          port: 28080,
          playerName: 'Bob',
        );
        await Future.delayed(const Duration(milliseconds: 500));

        expect(controller.session.sessionState, OnlineSessionState.browsing);
        expect(controller.session.serverCapabilities?.region, 'MOCK-EAST');

        // Create lobby
        await controller.createLobby(
          roomName: 'Bobs Room',
          maxPlayers: 4,
          isPrivate: false,
        );
        await Future.delayed(const Duration(milliseconds: 500));

        expect(controller.session.sessionState, OnlineSessionState.lobby);
        expect(controller.session.lobby?.name, 'Bobs Room');

        // Disconnect
        await controller.disconnect();
        expect(
          controller.session.sessionState,
          OnlineSessionState.disconnected,
        );
      },
    );
  });
}
