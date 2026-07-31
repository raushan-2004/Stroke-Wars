import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';

/// Gameplay states for the online game state machine.
enum OnlineGameState {
  loading,
  waitingForPlayers,
  countdown,
  playing,
  roundEnd,
  results,
  reconnecting,
  disconnected,
}

/// Immutable record of latency metrics, ping levels, and synchronization flags.
class NetworkOverlayState {
  const NetworkOverlayState({
    required this.latency,
    required this.jitter,
    required this.packetLoss,
    required this.reconnectStatus,
    required this.synchronizationStatus,
  });

  factory NetworkOverlayState.initial() => const NetworkOverlayState(
        latency: 0.0,
        jitter: 0.0,
        packetLoss: 0.0,
        reconnectStatus: 'Connected',
        synchronizationStatus: 'Synchronized',
      );

  final double latency;
  final double jitter;
  final double packetLoss;
  final String reconnectStatus;
  final String synchronizationStatus;

  NetworkOverlayState copyWith({
    double? latency,
    double? jitter,
    double? packetLoss,
    String? reconnectStatus,
    String? synchronizationStatus,
  }) {
    return NetworkOverlayState(
      latency: latency ?? this.latency,
      jitter: jitter ?? this.jitter,
      packetLoss: packetLoss ?? this.packetLoss,
      reconnectStatus: reconnectStatus ?? this.reconnectStatus,
      synchronizationStatus: synchronizationStatus ?? this.synchronizationStatus,
    );
  }
}

/// Immutable representation of the complete online gameplay session.
class OnlineGameSession {
  const OnlineGameSession({
    required this.onlineSession,
    this.currentMatch,
    required this.canvasState,
    required this.players,
    required this.connectionQuality,
    required this.synchronizationState,
    this.currentDrawer,
    this.round,
    required this.onlineGameState,
    required this.networkOverlayState,
  });

  factory OnlineGameSession.initial() => OnlineGameSession(
        onlineSession: OnlineSession.initial(),
        canvasState: CanvasState.initial(),
        players: const [],
        connectionQuality: ConnectionQuality.disconnected,
        synchronizationState: SynchronizationState.outOfSync,
        onlineGameState: OnlineGameState.disconnected,
        networkOverlayState: NetworkOverlayState.initial(),
      );

  final OnlineSession onlineSession;
  final Match? currentMatch;
  final CanvasState canvasState;
  final List<PlayerConnection> players;
  final ConnectionQuality connectionQuality;
  final SynchronizationState synchronizationState;
  final String? currentDrawer;
  final Round? round;
  final OnlineGameState onlineGameState;
  final NetworkOverlayState networkOverlayState;

  OnlineGameSession copyWith({
    OnlineSession? onlineSession,
    Match? Function()? currentMatch,
    CanvasState? canvasState,
    List<PlayerConnection>? players,
    ConnectionQuality? connectionQuality,
    SynchronizationState? synchronizationState,
    String? Function()? currentDrawer,
    Round? Function()? round,
    OnlineGameState? onlineGameState,
    NetworkOverlayState? networkOverlayState,
  }) {
    return OnlineGameSession(
      onlineSession: onlineSession ?? this.onlineSession,
      currentMatch: currentMatch != null ? currentMatch() : this.currentMatch,
      canvasState: canvasState ?? this.canvasState,
      players: players ?? this.players,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      synchronizationState: synchronizationState ?? this.synchronizationState,
      currentDrawer: currentDrawer != null ? currentDrawer() : this.currentDrawer,
      round: round != null ? round() : this.round,
      onlineGameState: onlineGameState ?? this.onlineGameState,
      networkOverlayState: networkOverlayState ?? this.networkOverlayState,
    );
  }
}
