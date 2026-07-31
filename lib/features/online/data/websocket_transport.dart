import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/multiplayer/domain/repositories/game_transport.dart';

/// Message buffer record representing queued packets during disconnects.
class BufferedMessage {
  const BufferedMessage({
    required this.peerId,
    required this.message,
    required this.expiry,
  });

  final String peerId;
  final String message;
  final DateTime expiry;
}

/// Robust WebSocket implementation of [GameTransport] with heartbeats,
/// exponential backoff reconnects, and FIFO message buffering.
class WebSocketTransport implements GameTransport {
  WebSocketTransport({
    this.pingInterval = const Duration(seconds: 3),
    this.pongTimeout = const Duration(seconds: 2),
    this.maxQueueSize = 100,
    this.messageExpiry = const Duration(seconds: 15),
  });

  final Duration pingInterval;
  final Duration pongTimeout;
  final int maxQueueSize;
  final Duration messageExpiry;

  WebSocket? _socket;
  final _messageStreamController =
      StreamController<TransportMessage>.broadcast();
  final _stateStreamController =
      StreamController<TransportConnectionState>.broadcast();
  TransportConnectionState _state = TransportConnectionState.disconnected;

  // Buffered messages queue
  final List<BufferedMessage> _buffer = [];

  // Reconnection variables
  bool _shouldReconnect = false;
  int _reconnectAttempts = 0;
  String? _lastAddress;
  int? _lastPort;

  // Heartbeat timers
  Timer? _heartbeatTimer;
  DateTime? _lastPongReceived;

  @override
  Stream<TransportMessage> get messages => _messageStreamController.stream;

  @override
  Stream<TransportConnectionState> get connectionState =>
      _stateStreamController.stream;

  TransportConnectionState get currentState => _state;

  @override
  Future<void> connect(String address, int port) async {
    _lastAddress = address;
    _lastPort = port;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (_state == TransportConnectionState.connected ||
        _state == TransportConnectionState.connecting) {
      return;
    }

    _updateState(TransportConnectionState.connecting);

    final url =
        _lastAddress!.startsWith('ws://') || _lastAddress!.startsWith('wss://')
        ? _lastAddress!
        : 'ws://$_lastAddress:$_lastPort/ws';

    try {
      _socket = await WebSocket.connect(
        url,
      ).timeout(const Duration(seconds: 5));
      _updateState(TransportConnectionState.connected);
      _reconnectAttempts = 0;

      // Start socket reader loop
      _socket!.listen(
        _onDataReceived,
        onError: _onSocketError,
        onDone: _onSocketClosed,
        cancelOnError: true,
      );

      _startHeartbeat();
      _flushBuffer();
    } catch (e) {
      AppLogger.instance.error('WebSocket connection to $url failed: $e');
      _updateState(TransportConnectionState.failed);
      _triggerReconnect();
    }
  }

  @override
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _stopHeartbeat();
    _buffer.clear();

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    _updateState(TransportConnectionState.disconnected);
  }

  @override
  Future<void> send(String peerId, String message) async {
    if (_state == TransportConnectionState.connected && _socket != null) {
      try {
        _socket!.add(message);
      } catch (e) {
        AppLogger.instance.error('Failed sending websocket packet: $e');
        _bufferMessage(peerId, message);
        _triggerReconnect();
      }
    } else {
      _bufferMessage(peerId, message);
    }
  }

  @override
  Future<void> broadcast(String message) async {
    await send('server', message);
  }

  // --- Message Buffering Policy ---
  void _bufferMessage(String peerId, String message) {
    // Evict expired messages from buffer
    final now = DateTime.now();
    _buffer.removeWhere((m) => m.expiry.isBefore(now));

    // Overflow check (FIFO)
    if (_buffer.length >= maxQueueSize) {
      _buffer.removeAt(0); // Discard oldest
      AppLogger.instance.warning(
        'WebSocket message buffer overflow. Discarding oldest message.',
      );
    }

    _buffer.add(
      BufferedMessage(
        peerId: peerId,
        message: message,
        expiry: now.add(messageExpiry),
      ),
    );
  }

  void _flushBuffer() {
    if (_buffer.isEmpty || _socket == null) return;

    final now = DateTime.now();
    // Filter out expired items
    final active = _buffer.where((m) => m.expiry.isAfter(now)).toList();
    _buffer.clear();

    for (final record in active) {
      send(record.peerId, record.message);
    }
  }

  // --- Socket Listeners ---
  void _onDataReceived(dynamic data) {
    if (data is String) {
      // Intercept Pong heartbeats
      if (data == 'pong' || data.contains('"type":"pong"')) {
        _lastPongReceived = DateTime.now();
        return;
      }

      if (!_messageStreamController.isClosed) {
        _messageStreamController.add(
          TransportMessage(senderId: 'server', content: data),
        );
      }
    }
  }

  void _onSocketError(dynamic error) {
    AppLogger.instance.error('WebSocket transport error: $error');
    _triggerReconnect();
  }

  void _onSocketClosed() {
    AppLogger.instance.info('WebSocket closed by remote host');
    _triggerReconnect();
  }

  // --- Reconnection Logic ---
  void _triggerReconnect() {
    _stopHeartbeat();
    _socket = null;
    _updateState(TransportConnectionState.disconnected);

    if (!_shouldReconnect) return;

    final delaySecs = _getBackoffDelay(_reconnectAttempts);
    _reconnectAttempts++;

    AppLogger.instance.info(
      'Scheduling automatic WebSocket reconnect in $delaySecs seconds (Attempt $_reconnectAttempts)',
    );

    Timer(Duration(seconds: delaySecs), () {
      if (_shouldReconnect) {
        _establishConnection();
      }
    });
  }

  int _getBackoffDelay(int attempt) {
    if (attempt == 0) return 1;
    if (attempt == 1) return 2;
    if (attempt == 2) return 4;
    return 8; // Max delay
  }

  // --- Heartbeat Protocol ---
  void _startHeartbeat() {
    _stopHeartbeat();
    _lastPongReceived = DateTime.now();

    _heartbeatTimer = Timer.periodic(pingInterval, (timer) {
      if (_socket == null) return;

      final now = DateTime.now();
      final limit = pingInterval.inMilliseconds + pongTimeout.inMilliseconds;
      if (now.difference(_lastPongReceived!).inMilliseconds > limit) {
        AppLogger.instance.warning('Heartbeat pong timeout. Closing socket.');
        _triggerReconnect();
        return;
      }

      // Send Ping
      try {
        _socket!.add('ping');
      } catch (_) {
        _triggerReconnect();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _updateState(TransportConnectionState newState) {
    _state = newState;
    if (!_stateStreamController.isClosed) {
      _stateStreamController.add(newState);
    }
  }

  void dispose() {
    _shouldReconnect = false;
    _stopHeartbeat();
    _socket?.close();
    _socket = null;
    _messageStreamController.close();
    _stateStreamController.close();
  }
}
