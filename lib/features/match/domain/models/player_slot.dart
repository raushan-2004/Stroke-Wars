import 'package:stroke_wars/features/match/domain/models/player_role.dart';

/// Represents a player occupying a slot within a match.
///
/// A [PlayerSlot] is immutable. All mutations return a new instance via
/// [copyWith]. Connectivity changes and role promotions should produce
/// new [PlayerSlot] values stored in the parent [Match].
class PlayerSlot {
  /// Creates an immutable [PlayerSlot].
  const PlayerSlot({
    required this.slotId,
    required this.playerId,
    required this.displayName,
    required this.role,
    this.avatarId = 'default',
    this.isConnected = true,
    this.isReady = false,
    this.totalScore = 0,
  });

  /// Creates a [PlayerSlot] from a JSON map.
  factory PlayerSlot.fromJson(Map<String, dynamic> json) => PlayerSlot(
    slotId: json['slotId'] as String,
    playerId: json['playerId'] as String,
    displayName: json['displayName'] as String,
    role: PlayerRole.values.firstWhere((r) => r.name == json['role']),
    avatarId: json['avatarId'] as String? ?? 'default',
    isConnected: json['isConnected'] as bool? ?? true,
    isReady: json['isReady'] as bool? ?? false,
    totalScore: json['totalScore'] as int? ?? 0,
  );

  /// Unique identifier for this slot within the match.
  final String slotId;

  /// The device/player UUID from the Player Identity System.
  final String playerId;

  /// Player display name at the time of joining.
  final String displayName;

  /// Current role within the match.
  final PlayerRole role;

  /// Avatar identifier for UI rendering.
  final String avatarId;

  /// Whether this player is currently connected.
  final bool isConnected;

  /// Whether this player has confirmed readiness.
  final bool isReady;

  /// Accumulated score across all completed rounds.
  final int totalScore;

  /// Returns a copy with the specified fields replaced.
  PlayerSlot copyWith({
    String? slotId,
    String? playerId,
    String? displayName,
    PlayerRole? role,
    String? avatarId,
    bool? isConnected,
    bool? isReady,
    int? totalScore,
  }) => PlayerSlot(
    slotId: slotId ?? this.slotId,
    playerId: playerId ?? this.playerId,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    avatarId: avatarId ?? this.avatarId,
    isConnected: isConnected ?? this.isConnected,
    isReady: isReady ?? this.isReady,
    totalScore: totalScore ?? this.totalScore,
  );

  /// Converts this [PlayerSlot] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'slotId': slotId,
    'playerId': playerId,
    'displayName': displayName,
    'role': role.name,
    'avatarId': avatarId,
    'isConnected': isConnected,
    'isReady': isReady,
    'totalScore': totalScore,
  };

  @override
  bool operator ==(Object other) =>
      other is PlayerSlot && other.slotId == slotId;

  @override
  int get hashCode => slotId.hashCode;

  @override
  String toString() =>
      'PlayerSlot($displayName, role=${role.name}, score=$totalScore)';
}
