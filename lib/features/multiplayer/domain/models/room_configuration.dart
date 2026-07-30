import 'package:stroke_wars/features/match/domain/models/match_configuration.dart';

/// Room configuration parameters.
class RoomConfiguration {
  const RoomConfiguration({
    required this.name,
    this.description = '',
    this.maxPlayers = 8,
    this.isPrivate = false,
    this.port = 18080,
    required this.matchConfiguration,
  });

  /// Human-readable lobby name.
  final String name;

  /// Lobby description or motd.
  final String description;

  /// Maximum allowed connections in this room.
  final int maxPlayers;

  /// Visibility flag.
  final bool isPrivate;

  /// Network port the host binds TCP / UDP discovery service to.
  final int port;

  /// Configuration passed down to the match engine.
  final MatchConfiguration matchConfiguration;

  RoomConfiguration copyWith({
    String? name,
    String? description,
    int? maxPlayers,
    bool? isPrivate,
    int? port,
    MatchConfiguration? matchConfiguration,
  }) {
    return RoomConfiguration(
      name: name ?? this.name,
      description: description ?? this.description,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      isPrivate: isPrivate ?? this.isPrivate,
      port: port ?? this.port,
      matchConfiguration: matchConfiguration ?? this.matchConfiguration,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'maxPlayers': maxPlayers,
        'isPrivate': isPrivate,
        'port': port,
        'matchConfiguration': matchConfiguration.toJson(),
      };

  factory RoomConfiguration.fromJson(Map<String, dynamic> json) => RoomConfiguration(
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        maxPlayers: json['maxPlayers'] as int? ?? 8,
        isPrivate: json['isPrivate'] as bool? ?? false,
        port: json['port'] as int? ?? 18080,
        matchConfiguration: MatchConfiguration.fromJson(json['matchConfiguration'] as Map<String, dynamic>),
      );
}
