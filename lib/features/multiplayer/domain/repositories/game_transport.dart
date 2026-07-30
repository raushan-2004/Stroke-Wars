import 'dart:async';

/// Connection state of the raw underlying game transport.
enum TransportConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

/// A wrapper for received transport messages.
class TransportMessage {
  const TransportMessage({
    required this.senderId,
    required this.content,
  });

  /// Identifier of the sender peer.
  final String senderId;

  /// String content of the packet.
  final String content;
}

/// Abstract network transport interface defining connection & transmission contracts.
///
/// Hides all low-level TCP/UDP socket implementations.
abstract class GameTransport {
  /// Connects to a remote host.
  Future<void> connect(String address, int port);

  /// Disconnects from the current connection or closes the server.
  Future<void> disconnect();

  /// Sends a raw message to a specific peer.
  Future<void> send(String peerId, String message);

  /// Broadcasts a raw message to all connected peers.
  Future<void> broadcast(String message);

  /// Stream emitting incoming messages from all connected peers.
  Stream<TransportMessage> get messages;

  /// Stream emitting current network connection state.
  Stream<TransportConnectionState> get connectionState;
}
