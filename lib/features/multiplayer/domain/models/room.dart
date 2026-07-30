import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_configuration.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';

/// Immutable model representing the multiplayer lobby / room.
class Room {
  const Room({
    required this.id,
    required this.configuration,
    required this.state,
    required this.host,
    required this.players,
    this.matchId,
  });

  /// Unique Room Identifier.
  final RoomId id;

  /// Room configuration parameters.
  final RoomConfiguration configuration;

  /// Lifecycle state of this room.
  final RoomState state;

  /// Peer metadata of the host device.
  final PeerInfo host;

  /// Current list of active player connections.
  final List<PlayerConnection> players;

  /// The active game match ID, if game is in progress.
  final MatchId? matchId;

  Room copyWith({
    RoomId? id,
    RoomConfiguration? configuration,
    RoomState? state,
    PeerInfo? host,
    List<PlayerConnection>? players,
    MatchId? matchId,
  }) {
    return Room(
      id: id ?? this.id,
      configuration: configuration ?? this.configuration,
      state: state ?? this.state,
      host: host ?? this.host,
      players: players ?? this.players,
      matchId: matchId ?? this.matchId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.value,
        'configuration': configuration.toJson(),
        'state': state.name,
        'host': host.toJson(),
        'players': players.map((p) => p.toJson()).toList(),
        'matchId': matchId?.value,
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: RoomId(json['id'] as String),
        configuration: RoomConfiguration.fromJson(json['configuration'] as Map<String, dynamic>),
        state: RoomState.values.byName(json['state'] as String),
        host: PeerInfo.fromJson(json['host'] as Map<String, dynamic>),
        players: (json['players'] as List<dynamic>)
            .map((p) => PlayerConnection.fromJson(p as Map<String, dynamic>))
            .toList(),
        matchId: json['matchId'] != null ? MatchId(json['matchId'] as String) : null,
      );
}
