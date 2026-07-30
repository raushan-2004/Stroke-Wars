import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
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
import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/multiplayer/application/client_controller.dart';
import 'package:stroke_wars/features/multiplayer/application/connection_manager.dart';
import 'package:stroke_wars/features/multiplayer/application/host_controller.dart';
import 'package:stroke_wars/features/multiplayer/application/peer_discovery_service.dart';
import 'package:stroke_wars/features/multiplayer/application/protocol_serializer.dart';
import 'package:stroke_wars/features/multiplayer/data/local_network_transport.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_configuration.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_snapshot.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';
import 'package:stroke_wars/features/multiplayer/domain/repositories/game_transport.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock / In-Memory Transport for Fast Unit Testing
// ─────────────────────────────────────────────────────────────────────────────

class MockTransport implements GameTransport {
  MockTransport({required this.isHost});

  final bool isHost;
  MockTransport? peer;

  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();
  final StreamController<TransportConnectionState> _stateController =
      StreamController<TransportConnectionState>.broadcast();

  @override
  Stream<TransportMessage> get messages => _messageController.stream;

  @override
  Stream<TransportConnectionState> get connectionState => _stateController.stream;

  @override
  Future<void> connect(String address, int port) async {
    _stateController.add(TransportConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _stateController.add(TransportConnectionState.disconnected);
  }

  @override
  Future<void> send(String peerId, String message) async {
    peer?._messageController.add(TransportMessage(
      senderId: isHost ? 'host' : peerId,
      content: message,
    ));
  }

  @override
  Future<void> broadcast(String message) async {
    await send('broadcast', message);
  }
}

void main() {
  group('Multiplayer Stage 6A — Unit & Integration Tests', () {
    late ProtocolSerializer serializer;

    setUp(() {
      serializer = ProtocolSerializer(
        currentProtocolVersion: 1,
        currentEngineVersion: '1.0.0',
      );
    });

    test('NetworkEnvelope serialization and parsing works', () {
      final envelope = NetworkEnvelope(
        messageId: const MessageId('msg-123'),
        sessionId: const SessionId('sess-456'),
        connectionId: const ConnectionId('conn-789'),
        protocolVersion: 1,
        engineVersion: '1.0.0',
        sequenceNumber: 42,
        acknowledgementNumber: 11,
        timestamp: DateTime(2026, 7, 30),
        payloadType: 'version',
        payload: const VersionMessage(protocolVersion: 1, engineVersion: '1.0.0').toJson(),
      );

      final encoded = serializer.encode(envelope);
      final decoded = serializer.decode(encoded);

      expect(decoded.messageId, const MessageId('msg-123'));
      expect(decoded.sessionId, const SessionId('sess-456'));
      expect(decoded.connectionId, const ConnectionId('conn-789'));
      expect(decoded.sequenceNumber, 42);
      expect(decoded.acknowledgementNumber, 11);
      expect(decoded.payloadType, 'version');

      final payload = serializer.decodePayload(decoded) as VersionMessage;
      expect(payload.protocolVersion, 1);
      expect(payload.engineVersion, '1.0.0');
    });

    test('ProtocolSerializer rejects invalid versions', () {
      final envelopeIncompatible = NetworkEnvelope(
        messageId: const MessageId('msg-123'),
        sessionId: const SessionId('sess-456'),
        connectionId: const ConnectionId('conn-789'),
        protocolVersion: 99, // Mismatch
        engineVersion: '9.9.9', // Mismatch
        sequenceNumber: 1,
        acknowledgementNumber: 0,
        timestamp: DateTime.now(),
        payloadType: 'version',
        payload: const VersionMessage(protocolVersion: 99, engineVersion: '9.9.9').toJson(),
      );

      final validationResult = serializer.validateVersions(envelopeIncompatible);
      expect(validationResult, contains('Protocol version mismatch'));
    });

    test('ConnectionManager tracks heartbeats, timeouts and sequence filters duplicates', () async {
      final hostTransport = MockTransport(isHost: true);
      final clientTransport = MockTransport(isHost: false);
      hostTransport.peer = clientTransport;
      clientTransport.peer = hostTransport;

      final clientManager = ConnectionManager(
        transport: clientTransport,
        serializer: serializer,
        sessionId: const SessionId('sess-1'),
        localConnectionId: const ConnectionId('client-conn'),
        isHost: false,
        heartbeatInterval: const Duration(seconds: 10),
        timeoutDuration: const Duration(seconds: 30),
      );

      final hostManager = ConnectionManager(
        transport: hostTransport,
        serializer: serializer,
        sessionId: const SessionId('sess-1'),
        localConnectionId: const ConnectionId('host-conn'),
        isHost: true,
        heartbeatInterval: const Duration(seconds: 10),
        timeoutDuration: const Duration(seconds: 30),
      );

      await clientManager.connect('localhost', 18080);
      await hostManager.connect('localhost', 18080);

      // Verify connected state
      expect(clientManager.currentState, NetworkConnectionState.connected);

      // Verify Host receives the packet (subscribe before sending)
      final receivedFuture = hostManager.inboundMessages.first;

      // Send payload
      await clientManager.sendPayload(const VersionMessage(protocolVersion: 1, engineVersion: '1.0.0'));

      final receivedEnvelope = await receivedFuture;
      expect(receivedEnvelope.connectionId, const ConnectionId('client-conn'));
      expect(receivedEnvelope.sequenceNumber, 1);

      // Duplicate envelope testing: resending envelope with seq <= 1 should be dropped/ignored
      final duplicateEnvelope = NetworkEnvelope(
        messageId: const MessageId('msg-dup'),
        sessionId: const SessionId('sess-1'),
        connectionId: const ConnectionId('client-conn'),
        protocolVersion: 1,
        engineVersion: '1.0.0',
        sequenceNumber: 1, // Duplicate sequence
        acknowledgementNumber: 0,
        timestamp: DateTime.now(),
        payloadType: 'heartbeat',
        payload: HeartbeatMessage(sentAt: DateTime.now()).toJson(),
      );

      // Inject duplicate directly to transport messages stream
      hostTransport._messageController.add(TransportMessage(
        senderId: 'client-conn',
        content: serializer.encode(duplicateEnvelope),
      ));

      // Wait a moment
      await Future.delayed(const Duration(milliseconds: 50));
      expect(hostManager.statistics.packetsDropped, greaterThanOrEqualTo(1)); // Packets dropped count incremented

      // Clean up managers
      clientManager.dispose();
      hostManager.dispose();
    });

    test('HostController and ClientController align and synchronize matches authoritative events', () async {
      // 1. Setup Controllers
      final hostTransport = MockTransport(isHost: true);
      final clientTransport = MockTransport(isHost: false);
      hostTransport.peer = clientTransport;
      clientTransport.peer = hostTransport;

      final clock = SystemClock();
      final rules = RuleEngine(
        wordRules: const WordRules(),
        victoryRules: const VictoryRules(),
        configurationRules: const ConfigurationRules(),
      );

      final hostMatchEventBus = MatchEventBus();
      final hostMatchController = MatchController(
        dispatcher: MatchEventDispatcher(bus: hostMatchEventBus),
        validator: MatchValidator(),
        rules: rules,
        scoring: const ScoringEngine(),
        wordSelector: WordSelector(
          repository: const DefaultWordList(),
          random: DefaultRandomProvider(),
        ),
        clock: clock,
        sequenceGenerator: SequenceGenerator(),
      );

      final hostCommandProcessor = MatchCommandProcessor(
        controller: hostMatchController,
        stateMachine: MatchStateMachine(validator: MatchValidator()),
        clock: clock,
      );

      final hostDrawingEventBus = DrawingEventBus();
      final hostCanvasController = CanvasController(
        renderQueue: RenderQueue(),
        dispatcher: DrawingEventDispatcher(eventBus: hostDrawingEventBus),
      );

      final hostManager = ConnectionManager(
        transport: hostTransport,
        serializer: serializer,
        sessionId: const SessionId('sess-abc'),
        localConnectionId: const ConnectionId('host-conn'),
        isHost: true,
      );

      final hostController = HostController(
        connectionManager: hostManager,
        matchController: hostMatchController,
        canvasController: hostCanvasController,
        commandProcessor: hostCommandProcessor,
        matchEventBus: hostMatchEventBus,
        drawingEventBus: hostDrawingEventBus,
      );

      // Client Controllers
      final clientMatchEventBus = MatchEventBus();
      final clientMatchController = MatchController(
        dispatcher: MatchEventDispatcher(bus: clientMatchEventBus),
        validator: MatchValidator(),
        rules: rules,
        scoring: const ScoringEngine(),
        wordSelector: WordSelector(
          repository: const DefaultWordList(),
          random: DefaultRandomProvider(),
        ),
        clock: clock,
        sequenceGenerator: SequenceGenerator(),
      );

      final clientDrawingEventBus = DrawingEventBus();
      final clientCanvasController = CanvasController(
        renderQueue: RenderQueue(),
        dispatcher: DrawingEventDispatcher(eventBus: clientDrawingEventBus),
      );

      final clientManager = ConnectionManager(
        transport: clientTransport,
        serializer: serializer,
        sessionId: const SessionId('sess-abc'),
        localConnectionId: const ConnectionId('client-conn'),
        isHost: false,
      );

      final clientController = ClientController(
        connectionManager: clientManager,
        matchController: clientMatchController,
        canvasController: clientCanvasController,
        matchEventBus: clientMatchEventBus,
      );

      // Connect Host and Client
      await hostManager.connect('localhost', 18080);
      hostController.createRoom(
        const RoomId('room-1'),
        const PeerInfo(id: PeerId('host'), displayName: 'Alice Host', address: '127.0.0.1', port: 18080),
        RoomConfiguration(
          name: 'Super Room',
          matchConfiguration: MatchConfiguration(
            allowedCategories: const [WordCategory.animals],
            maxPlayers: 4,
          ),
        ),
      );

      // Join from Client
      await clientController.joinRoom(
        '127.0.0.1',
        18080,
        const PeerInfo(id: PeerId('client'), displayName: 'Bob Client', address: '127.0.0.1', port: 18081),
      );

      // Let messages fly
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify Bob Client added to Room list on both client and host
      expect(hostController.room!.players.length, 2);
      expect(clientController.room!.players.length, 2);

      clientController.sendCanvasEvent(
        StrokeStarted(
          strokeId: 's1',
          playerId: 'client-conn',
          brushId: 'classic',
          color: '#ffffff',
          width: 8.0,
          opacity: 1.0,
          timestamp: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));
      expect(hostCanvasController.events.length, 1);

      // Clean up
      hostController.dispose();
      clientController.dispose();
      hostManager.dispose();
      clientManager.dispose();
    });

    test('PeerDiscoveryService advertises and scans valid rooms', () async {
      final discovery = PeerDiscoveryService(
        discoveryPort: 18085,
      );

      // Wait a moment to bind and advertise
      await discovery.startAdvertising(
        roomId: const RoomId('room-discover'),
        hostName: 'TestHost',
        playerCount: 1,
        maxPlayers: 4,
        gamePort: 18080,
        roomState: 'waiting',
        interval: const Duration(milliseconds: 50),
      );

      await discovery.startBrowsing();

      // Listen for discovered rooms
      final Completer<List<DiscoveredRoom>> completer = Completer();
      final sub = discovery.discoveredRooms.listen((list) {
        if (list.isNotEmpty && !completer.isCompleted) {
          completer.complete(list);
        }
      });

      final rooms = await completer.future.timeout(const Duration(seconds: 4), onTimeout: () => []);
      expect(rooms, isNotEmpty);
      expect(rooms.first.roomId, const RoomId('room-discover'));
      expect(rooms.first.hostName, 'TestHost');

      await discovery.stopAdvertising();
      await discovery.stopBrowsing();
      await sub.cancel();
    });

    test('LocalNetworkTransport connects, disconnects, and broadcasts real TCP sockets', () async {
      final host = LocalNetworkTransport(isHost: true);
      final client = LocalNetworkTransport(isHost: false);

      await host.connect('127.0.0.1', 18090);
      await client.connect('127.0.0.1', 18090);

      final Completer<TransportMessage> msgCompleter = Completer();
      final sub = host.messages.listen((msg) {
        if (!msgCompleter.isCompleted) {
          msgCompleter.complete(msg);
        }
      });

      await client.broadcast('Hello Real Socket');

      final msg = await msgCompleter.future.timeout(const Duration(seconds: 2));
      expect(msg.content, 'Hello Real Socket');

      await sub.cancel();
      await client.disconnect();
      await host.disconnect();
    });
  });
}
