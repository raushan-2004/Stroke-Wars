import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/multiplayer/domain/repositories/game_transport.dart';

/// TCP implementation of [GameTransport] for LAN multiplayer.
class LocalNetworkTransport implements GameTransport {
  LocalNetworkTransport({required this.isHost});

  /// Flags whether this transport instance behaves as a Host (Server) or Client.
  final bool isHost;

  ServerSocket? _serverSocket;
  Socket? _clientSocket;

  final Map<String, Socket> _connections = {};
  final StreamController<TransportMessage> _messageController =
      StreamController<TransportMessage>.broadcast();
  final StreamController<TransportConnectionState> _stateController =
      StreamController<TransportConnectionState>.broadcast();

  TransportConnectionState _currentState = TransportConnectionState.disconnected;

  void _updateState(TransportConnectionState newState) {
    if (_currentState == newState) return;
    _currentState = newState;
    _stateController.add(newState);
    AppLogger.instance.debug('Transport state changed to: $newState');
  }

  @override
  Stream<TransportMessage> get messages => _messageController.stream;

  @override
  Stream<TransportConnectionState> get connectionState => _stateController.stream;

  @override
  Future<void> connect(String address, int port) async {
    await disconnect();
    _updateState(TransportConnectionState.connecting);

    if (isHost) {
      try {
        // Host mode: Start server socket
        _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
        _updateState(TransportConnectionState.connected);
        AppLogger.instance.info('Host ServerSocket bound to port: $port');

        _serverSocket!.listen(
          _handleIncomingConnection,
          onError: (Object error) {
            AppLogger.instance.error('ServerSocket error: $error');
            _updateState(TransportConnectionState.failed);
          },
        );
      } catch (e) {
        AppLogger.instance.error('Failed to bind ServerSocket: $e');
        _updateState(TransportConnectionState.failed);
        rethrow;
      }
    } else {
      try {
        // Client mode: Connect to Host
        _clientSocket = await Socket.connect(address, port, timeout: const Duration(seconds: 5));
        _updateState(TransportConnectionState.connected);
        AppLogger.instance.info('Client connected to Host at $address:$port');

        final String hostId = '$address:$port';
        _clientSocket!
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (String line) {
            _messageController.add(TransportMessage(senderId: hostId, content: line));
          },
          onError: (Object error) {
            AppLogger.instance.error('Client socket stream error: $error');
            _updateState(TransportConnectionState.failed);
          },
          onDone: () {
            AppLogger.instance.info('Client socket disconnected by server');
            disconnect();
          },
        );
      } catch (e) {
        AppLogger.instance.error('Client failed to connect: $e');
        _updateState(TransportConnectionState.failed);
        rethrow;
      }
    }
  }

  void _handleIncomingConnection(Socket socket) {
    final String connId = '${socket.remoteAddress.address}:${socket.remotePort}';
    _connections[connId] = socket;
    AppLogger.instance.info('New connection accepted: $connId');

    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (String line) {
        _messageController.add(TransportMessage(senderId: connId, content: line));
      },
      onError: (Object error) {
        AppLogger.instance.error('Error on socket $connId: $error');
        _closeConnection(connId);
      },
      onDone: () {
        AppLogger.instance.info('Socket $connId closed');
        _closeConnection(connId);
      },
    );
  }

  void _closeConnection(String connId) {
    final Socket? socket = _connections.remove(connId);
    if (socket != null) {
      socket.destroy();
      AppLogger.instance.debug('Destroyed socket for: $connId');
    }
  }

  @override
  Future<void> disconnect() async {
    _updateState(TransportConnectionState.disconnected);

    if (_serverSocket != null) {
      await _serverSocket!.close();
      _serverSocket = null;
    }

    if (_clientSocket != null) {
      _clientSocket!.destroy();
      _clientSocket = null;
    }

    final List<String> activeIds = _connections.keys.toList();
    for (final String connId in activeIds) {
      _closeConnection(connId);
    }
    _connections.clear();
  }

  @override
  Future<void> send(String peerId, String message) async {
    if (isHost) {
      final Socket? socket = _connections[peerId];
      if (socket != null) {
        socket.write('$message\n');
        await socket.flush();
      } else {
        AppLogger.instance.warning('Cannot send message, peerId $peerId not found');
      }
    } else {
      if (_clientSocket != null) {
        _clientSocket!.write('$message\n');
        await _clientSocket!.flush();
      } else {
        AppLogger.instance.warning('Cannot send message, client not connected');
      }
    }
  }

  @override
  Future<void> broadcast(String message) async {
    if (isHost) {
      for (final Socket socket in _connections.values) {
        socket.write('$message\n');
        await socket.flush();
      }
    } else {
      await send('host', message);
    }
  }
}
