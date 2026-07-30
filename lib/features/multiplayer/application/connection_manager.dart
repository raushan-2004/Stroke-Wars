import 'dart:async';

import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/multiplayer/application/protocol_serializer.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_statistics.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';
import 'package:stroke_wars/features/multiplayer/domain/repositories/game_transport.dart';

/// Manages socket health, ping-pong latency loops, heartbeat timers, reconnect strategies, and diagnostic statistics.
class ConnectionManager {
  ConnectionManager({
    required this.transport,
    required this.serializer,
    required this.sessionId,
    required this.localConnectionId,
    required this.isHost,
    this.heartbeatInterval = const Duration(seconds: 2),
    this.timeoutDuration = const Duration(seconds: 6),
    this.maxReconnectAttempts = 3,
  }) {
    _init();
  }

  final GameTransport transport;
  final ProtocolSerializer serializer;
  final SessionId sessionId;
  final ConnectionId localConnectionId;
  final bool isHost;
  final Duration heartbeatInterval;
  final Duration timeoutDuration;
  final int maxReconnectAttempts;

  int _outboundSeqNum = 0;
  int _lastInboundSeqNum = 0;
  int _reconnectAttempts = 0;
  double _lastLatencyMs = 0.0;

  NetworkStatistics _stats = const NetworkStatistics();
  final StreamController<NetworkStatistics> _statsController =
      StreamController<NetworkStatistics>.broadcast();

  NetworkConnectionState _currentState = NetworkConnectionState.disconnected;
  final StreamController<NetworkConnectionState> _stateController =
      StreamController<NetworkConnectionState>.broadcast();

  final StreamController<NetworkEnvelope> _inboundMessageController =
      StreamController<NetworkEnvelope>.broadcast();

  // Track heartbeat/presence times per connection identifier
  final Map<String, DateTime> _peerLastSeen = {};
  final StreamController<String> _peerTimeoutController =
      StreamController<String>.broadcast();

  Timer? _heartbeatTimer;
  Timer? _timeoutCheckTimer;
  StreamSubscription<TransportMessage>? _messageSub;
  StreamSubscription<TransportConnectionState>? _stateSub;

  String? _lastConnectedAddress;
  int? _lastConnectedPort;

  // Track sequence numbers received per sender to filter duplicates
  final Map<String, int> _lastSeenSequencePerPeer = {};

  void _init() {
    _messageSub = transport.messages.listen(_handleRawMessage);
    _stateSub = transport.connectionState.listen(_handleTransportState);
  }

  Stream<NetworkEnvelope> get inboundMessages =>
      _inboundMessageController.stream;
  NetworkStatistics get statistics => _stats;
  Stream<NetworkStatistics> get onStatisticsChanged => _statsController.stream;
  Stream<NetworkConnectionState> get connectionState => _stateController.stream;
  Stream<String> get onPeerTimeout => _peerTimeoutController.stream;
  NetworkConnectionState get currentState => _currentState;

  void _updateState(NetworkConnectionState newState) {
    if (_currentState == newState) return;
    _currentState = newState;
    _stateController.add(newState);
    AppLogger.instance.debug('ConnectionManager state: $newState');
  }

  void _updateStats(NetworkStatistics newStats) {
    _stats = newStats;
    _statsController.add(_stats);
  }

  /// Starts connection sequence.
  Future<void> connect(String address, int port) async {
    _lastConnectedAddress = address;
    _lastConnectedPort = port;
    _updateState(NetworkConnectionState.connecting);
    try {
      await transport.connect(address, port);
    } catch (e) {
      _updateState(NetworkConnectionState.failed);
      rethrow;
    }
  }

  /// Disconnects the session.
  Future<void> disconnect() async {
    _stopTimers();
    await transport.disconnect();
    _updateState(NetworkConnectionState.disconnected);
  }

  void _startTimers() {
    _stopTimers();

    // Setup periodic heartbeats
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _sendPingOrHeartbeat();
    });

    // Setup periodic timeout checks
    _timeoutCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTimeouts();
    });
  }

  void _stopTimers() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
  }

  void _sendPingOrHeartbeat() {
    if (_currentState != NetworkConnectionState.connected) return;

    if (isHost) {
      // Host broadcasts Heartbeat
      sendPayload(HeartbeatMessage(sentAt: DateTime.now()));
    } else {
      // Client sends Ping to Host to track latency
      sendPayload(PingMessage(sentAt: DateTime.now()));
    }
  }

  void _checkTimeouts() {
    final now = DateTime.now();
    if (isHost) {
      final List<String> timedOutPeers = [];
      _peerLastSeen.forEach((peerId, lastSeen) {
        if (now.difference(lastSeen) > timeoutDuration) {
          timedOutPeers.add(peerId);
        }
      });

      for (final peerId in timedOutPeers) {
        AppLogger.instance.warning('Peer timeout detected: $peerId');
        _peerLastSeen.remove(peerId);
        _peerTimeoutController.add(peerId);
        _updateStats(
          _stats.copyWith(heartbeatFailures: _stats.heartbeatFailures + 1),
        );
      }
    } else {
      // Client checks last seen from Host (represented as 'host' or host address)
      final hostLastSeen = _peerLastSeen['host'];
      if (hostLastSeen != null &&
          now.difference(hostLastSeen) > timeoutDuration) {
        AppLogger.instance.warning(
          'Host heartbeat timeout. Attempting reconnect...',
        );
        _peerLastSeen.clear();
        _handleHostTimeout();
      }
    }
  }

  void _handleHostTimeout() {
    _stopTimers();
    _updateState(NetworkConnectionState.reconnecting);
    _updateStats(
      _stats.copyWith(
        reconnectCount: _stats.reconnectCount + 1,
        heartbeatFailures: _stats.heartbeatFailures + 1,
      ),
    );
    _attemptReconnect();
  }

  Future<void> _attemptReconnect() async {
    if (_currentState != NetworkConnectionState.reconnecting) return;
    if (_reconnectAttempts >= maxReconnectAttempts) {
      AppLogger.instance.error(
        'Max reconnect attempts reached. Connection failed.',
      );
      _updateState(NetworkConnectionState.failed);
      return;
    }

    _reconnectAttempts++;
    AppLogger.instance.info(
      'Reconnection attempt $_reconnectAttempts/$maxReconnectAttempts...',
    );
    try {
      await transport.connect(_lastConnectedAddress!, _lastConnectedPort!);
      // If success, state switches to connected via _handleTransportState
    } catch (e) {
      AppLogger.instance.warning('Reconnect attempt failed: $e');
      Future.delayed(const Duration(seconds: 2), _attemptReconnect);
    }
  }

  /// Sends a concrete [NetworkMessage] wrapped inside a new sequenced [NetworkEnvelope].
  Future<void> sendPayload(NetworkMessage msg, {String? targetPeerId}) async {
    _outboundSeqNum++;
    final envelope = NetworkEnvelope(
      messageId: MessageId(
        'msg_${DateTime.now().microsecondsSinceEpoch}_${localConnectionId.value}',
      ),
      sessionId: sessionId,
      connectionId: localConnectionId,
      protocolVersion: serializer.currentProtocolVersion,
      engineVersion: serializer.currentEngineVersion,
      sequenceNumber: _outboundSeqNum,
      acknowledgementNumber: _lastInboundSeqNum,
      timestamp: DateTime.now(),
      payloadType: msg.type,
      payload: msg.toJson(),
    );

    final raw = serializer.encode(envelope);
    _updateStats(_stats.copyWith(packetsSent: _stats.packetsSent + 1));

    if (targetPeerId != null) {
      await transport.send(targetPeerId, raw);
    } else {
      await transport.broadcast(raw);
    }
  }

  void _handleRawMessage(TransportMessage rawMsg) {
    try {
      final envelope = serializer.decode(rawMsg.content);
      _updateStats(
        _stats.copyWith(packetsReceived: _stats.packetsReceived + 1),
      );

      // 1. Validate version compatibility
      final versionErr = serializer.validateVersions(envelope);
      if (versionErr != null) {
        AppLogger.instance.warning(versionErr);
        sendPayload(
          ErrorMessage(code: 'PROTOCOL_MISMATCH', message: versionErr),
          targetPeerId: rawMsg.senderId,
        );
        return;
      }

      // 2. Duplicate Detection & Ordering Validation
      final String sender = envelope.connectionId.value;
      final int lastSeq = _lastSeenSequencePerPeer[sender] ?? 0;
      if (envelope.sequenceNumber <= lastSeq) {
        // Duplicate or out-of-order stale packet, drop it
        _updateStats(
          _stats.copyWith(packetsDropped: _stats.packetsDropped + 1),
        );
        return;
      }
      _lastSeenSequencePerPeer[sender] = envelope.sequenceNumber;
      _lastInboundSeqNum = envelope.sequenceNumber;

      // 3. Heartbeat Update
      final String presenceKey = isHost ? rawMsg.senderId : 'host';
      _peerLastSeen[presenceKey] = DateTime.now();

      // 4. Process inner ping/pong messages to update latency tracking
      final payload = serializer.decodePayload(envelope);
      if (payload is PingMessage) {
        // Reply immediately with Pong
        sendPayload(
          PongMessage(pingSentAt: payload.sentAt, sentAt: DateTime.now()),
          targetPeerId: rawMsg.senderId,
        );
      } else if (payload is PongMessage) {
        final now = DateTime.now();
        final rtt = now
            .difference(payload.pingSentAt)
            .inMilliseconds
            .toDouble();
        final double jitter = _lastLatencyMs == 0.0
            ? 0.0
            : (rtt - _lastLatencyMs).abs();
        _lastLatencyMs = rtt;

        _updateStats(
          _stats.copyWith(
            latencyMs: rtt,
            jitterMs: _stats.jitterMs * 0.8 + jitter * 0.2,
          ),
        );
      } else if (payload is HeartbeatMessage) {
        // Received heartbeat from Host, presence updated
      }

      // 5. Forward envelope to controllers
      _inboundMessageController.add(envelope);
    } catch (e) {
      AppLogger.instance.error('Failed to parse network message: $e');
      _updateStats(_stats.copyWith(packetsDropped: _stats.packetsDropped + 1));
    }
  }

  void _handleTransportState(TransportConnectionState state) {
    switch (state) {
      case TransportConnectionState.connected:
        _reconnectAttempts = 0;
        _peerLastSeen[isHost ? 'clients' : 'host'] = DateTime.now();
        _updateState(NetworkConnectionState.connected);
        _startTimers();
        break;
      case TransportConnectionState.disconnected:
        _stopTimers();
        _updateState(NetworkConnectionState.disconnected);
        break;
      case TransportConnectionState.failed:
        if (!isHost && _currentState == NetworkConnectionState.connected) {
          _handleHostTimeout();
        } else {
          _stopTimers();
          _updateState(NetworkConnectionState.failed);
        }
        break;
      case TransportConnectionState.connecting:
        _updateState(NetworkConnectionState.connecting);
        break;
    }
  }

  void dispose() {
    _stopTimers();
    _messageSub?.cancel();
    _stateSub?.cancel();
    _statsController.close();
    _stateController.close();
    _inboundMessageController.close();
    _peerTimeoutController.close();
  }
}
