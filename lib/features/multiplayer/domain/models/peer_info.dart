import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';

/// Immutable model representing information about a multiplayer peer device.
class PeerInfo {
  const PeerInfo({
    required this.id,
    required this.displayName,
    required this.address,
    required this.port,
  });

  /// Unique peer ID.
  final PeerId id;

  /// User display name on this device.
  final String displayName;

  /// Network IP address of the peer device.
  final String address;

  /// Network port of the peer device.
  final int port;

  /// Converts this instance to a JSON map.
  Map<String, dynamic> toJson() => {
    'id': id.value,
    'displayName': displayName,
    'address': address,
    'port': port,
  };

  /// Restores this instance from a JSON map.
  factory PeerInfo.fromJson(Map<String, dynamic> json) => PeerInfo(
    id: PeerId(json['id'] as String),
    displayName: json['displayName'] as String,
    address: json['address'] as String,
    port: json['port'] as int,
  );
}
