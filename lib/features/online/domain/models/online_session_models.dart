import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_statistics.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';

/// Connection and authorization states of an Online Session.
enum AuthenticationState {
  unauthenticated,
  authenticating,
  authenticated,
  authenticationFailed,
}

/// Explicit lifecycle states of the Online session machine.
enum OnlineSessionState {
  disconnected,
  connecting,
  connected,
  browsing,
  lobby,
  waiting,
  gameplay,
  closed,
}

/// Immutable representation of the negotiated remote Server capabilities.
class ServerCapabilities {
  const ServerCapabilities({
    required this.protocolVersion,
    required this.engineVersion,
    required this.maximumPlayers,
    required this.supportedFeatures,
    required this.compressionSupport,
    required this.replaySupport,
    required this.region,
  });

  factory ServerCapabilities.initial() => const ServerCapabilities(
    protocolVersion: 1,
    engineVersion: '1.0.0',
    maximumPlayers: 8,
    supportedFeatures: [],
    compressionSupport: false,
    replaySupport: false,
    region: 'US-East',
  );

  final int protocolVersion;
  final String engineVersion;
  final int maximumPlayers;
  final List<String> supportedFeatures;
  final bool compressionSupport;
  final bool replaySupport;
  final String region;

  ServerCapabilities copyWith({
    int? protocolVersion,
    String? engineVersion,
    int? maximumPlayers,
    List<String>? supportedFeatures,
    bool? compressionSupport,
    bool? replaySupport,
    String? region,
  }) {
    return ServerCapabilities(
      protocolVersion: protocolVersion ?? this.protocolVersion,
      engineVersion: engineVersion ?? this.engineVersion,
      maximumPlayers: maximumPlayers ?? this.maximumPlayers,
      supportedFeatures: supportedFeatures ?? this.supportedFeatures,
      compressionSupport: compressionSupport ?? this.compressionSupport,
      replaySupport: replaySupport ?? this.replaySupport,
      region: region ?? this.region,
    );
  }

  Map<String, dynamic> toJson() => {
    'protocolVersion': protocolVersion,
    'engineVersion': engineVersion,
    'maximumPlayers': maximumPlayers,
    'supportedFeatures': supportedFeatures,
    'compressionSupport': compressionSupport,
    'replaySupport': replaySupport,
    'region': region,
  };

  factory ServerCapabilities.fromJson(Map<String, dynamic> json) =>
      ServerCapabilities(
        protocolVersion: json['protocolVersion'] as int? ?? 1,
        engineVersion: json['engineVersion'] as String? ?? '1.0.0',
        maximumPlayers: json['maximumPlayers'] as int? ?? 8,
        supportedFeatures: List<String>.from(
          json['supportedFeatures'] as List? ?? [],
        ),
        compressionSupport: json['compressionSupport'] as bool? ?? false,
        replaySupport: json['replaySupport'] as bool? ?? false,
        region: json['region'] as String? ?? 'US-East',
      );
}

/// Immutable representation of the Online Multiplayer Lobby/Room.
class OnlineLobby {
  const OnlineLobby({
    required this.id,
    required this.name,
    required this.hostId,
    required this.players,
    required this.isPrivate,
    this.privateCode,
    required this.maxPlayers,
    required this.metadata,
  });

  final String id;
  final String name;
  final String hostId;
  final List<PlayerConnection> players;
  final bool isPrivate;
  final String? privateCode;
  final int maxPlayers;
  final Map<String, String> metadata;

  OnlineLobby copyWith({
    String? id,
    String? name,
    String? hostId,
    List<PlayerConnection>? players,
    bool? isPrivate,
    String? Function()? privateCode,
    int? maxPlayers,
    Map<String, String>? metadata,
  }) {
    return OnlineLobby(
      id: id ?? this.id,
      name: name ?? this.name,
      hostId: hostId ?? this.hostId,
      players: players ?? this.players,
      isPrivate: isPrivate ?? this.isPrivate,
      privateCode: privateCode != null ? privateCode() : this.privateCode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hostId': hostId,
    'players': players.map((p) => p.toJson()).toList(),
    'isPrivate': isPrivate,
    'privateCode': privateCode,
    'maxPlayers': maxPlayers,
    'metadata': metadata,
  };

  factory OnlineLobby.fromJson(Map<String, dynamic> json) => OnlineLobby(
    id: json['id'] as String,
    name: json['name'] as String,
    hostId: json['hostId'] as String,
    players: (json['players'] as List? ?? [])
        .map((p) => PlayerConnection.fromJson(p as Map<String, dynamic>))
        .toList(),
    isPrivate: json['isPrivate'] as bool? ?? false,
    privateCode: json['privateCode'] as String?,
    maxPlayers: json['maxPlayers'] as int? ?? 8,
    metadata: Map<String, String>.from(json['metadata'] as Map? ?? {}),
  );
}

/// Immutable main model representing the Online Session State.
class OnlineSession {
  const OnlineSession({
    this.sessionId,
    this.player,
    this.lobby,
    required this.authenticationState,
    required this.connectionState,
    required this.connectionQuality,
    required this.synchronizationState,
    required this.networkStatistics,
    this.serverCapabilities,
    required this.sessionState,
    required this.canvasState,
    this.currentMatch,
  });

  factory OnlineSession.initial() => OnlineSession(
    authenticationState: AuthenticationState.unauthenticated,
    connectionState: NetworkConnectionState.disconnected,
    connectionQuality: ConnectionQuality.disconnected,
    synchronizationState: SynchronizationState.outOfSync,
    networkStatistics: const NetworkStatistics(),
    sessionState: OnlineSessionState.disconnected,
    canvasState: CanvasState.initial(),
  );

  final String? sessionId;
  final PeerInfo? player;
  final OnlineLobby? lobby;
  final AuthenticationState authenticationState;
  final NetworkConnectionState connectionState;
  final ConnectionQuality connectionQuality;
  final SynchronizationState synchronizationState;
  final NetworkStatistics networkStatistics;
  final ServerCapabilities? serverCapabilities;
  final OnlineSessionState sessionState;
  final CanvasState canvasState;
  final Match? currentMatch;

  OnlineSession copyWith({
    String? Function()? sessionId,
    PeerInfo? Function()? player,
    OnlineLobby? Function()? lobby,
    AuthenticationState? authenticationState,
    NetworkConnectionState? connectionState,
    ConnectionQuality? connectionQuality,
    SynchronizationState? synchronizationState,
    NetworkStatistics? networkStatistics,
    ServerCapabilities? Function()? serverCapabilities,
    OnlineSessionState? sessionState,
    CanvasState? canvasState,
    Match? Function()? currentMatch,
  }) {
    return OnlineSession(
      sessionId: sessionId != null ? sessionId() : this.sessionId,
      player: player != null ? player() : this.player,
      lobby: lobby != null ? lobby() : this.lobby,
      authenticationState: authenticationState ?? this.authenticationState,
      connectionState: connectionState ?? this.connectionState,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      synchronizationState: synchronizationState ?? this.synchronizationState,
      networkStatistics: networkStatistics ?? this.networkStatistics,
      serverCapabilities: serverCapabilities != null
          ? serverCapabilities()
          : this.serverCapabilities,
      sessionState: sessionState ?? this.sessionState,
      canvasState: canvasState ?? this.canvasState,
      currentMatch: currentMatch != null ? currentMatch() : this.currentMatch,
    );
  }
}
