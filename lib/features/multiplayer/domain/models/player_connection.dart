import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';

/// Represents a player's connection status and presence within a multiplayer session.
class PlayerConnection {
  const PlayerConnection({
    required this.peerInfo,
    required this.connectionState,
    required this.isReady,
    required this.lastSeen,
  });

  /// Identity and network coordinates of the peer.
  final PeerInfo peerInfo;

  /// Connection state of this client connection.
  final NetworkConnectionState connectionState;

  /// Readiness indicator within the room lobby.
  final bool isReady;

  /// Timestamp of the last successful message or heartbeat received.
  final DateTime lastSeen;

  PlayerConnection copyWith({
    PeerInfo? peerInfo,
    NetworkConnectionState? connectionState,
    bool? isReady,
    DateTime? lastSeen,
  }) {
    return PlayerConnection(
      peerInfo: peerInfo ?? this.peerInfo,
      connectionState: connectionState ?? this.connectionState,
      isReady: isReady ?? this.isReady,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'peerInfo': peerInfo.toJson(),
        'connectionState': connectionState.name,
        'isReady': isReady,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory PlayerConnection.fromJson(Map<String, dynamic> json) => PlayerConnection(
        peerInfo: PeerInfo.fromJson(json['peerInfo'] as Map<String, dynamic>),
        connectionState: NetworkConnectionState.values.byName(json['connectionState'] as String),
        isReady: json['isReady'] as bool,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
      );
}
