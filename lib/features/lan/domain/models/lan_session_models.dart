import 'package:flutter/material.dart';
import 'package:stroke_wars/features/canvas/domain/models/canvas_state.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_connection_state.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/network_statistics.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room.dart';

/// Represents connection latency quality bands.
enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
  disconnected;

  /// Helper to calculate quality based on raw latency.
  static ConnectionQuality fromLatency(double latencyMs) {
    if (latencyMs <= 0) return ConnectionQuality.disconnected;
    if (latencyMs < 50) return ConnectionQuality.excellent;
    if (latencyMs < 120) return ConnectionQuality.good;
    if (latencyMs < 250) return ConnectionQuality.fair;
    return ConnectionQuality.poor;
  }
}

/// Represents the synchronization health state between host and client.
enum SynchronizationState { synchronizing, synchronized, recovering, outOfSync }

/// Explicit lifecycle states for the LAN multiplayer session.
enum LANSessionLifecycleState {
  discovering,
  joining,
  lobby,
  loading,
  playing,
  results,
  disconnected,
  closed,
}

/// Debug diagnostics model containing detailed network sequence info.
class SynchronizationDiagnostics {
  const SynchronizationDiagnostics({
    required this.lastSequenceReceived,
    required this.lastSnapshotVersion,
    required this.pendingSnapshots,
    required this.pendingEvents,
    required this.reconnectAttempts,
    required this.averageLatency,
  });

  factory SynchronizationDiagnostics.initial() =>
      const SynchronizationDiagnostics(
        lastSequenceReceived: 0,
        lastSnapshotVersion: 0,
        pendingSnapshots: 0,
        pendingEvents: 0,
        reconnectAttempts: 0,
        averageLatency: 0.0,
      );

  final int lastSequenceReceived;
  final int lastSnapshotVersion;
  final int pendingSnapshots;
  final int pendingEvents;
  final int reconnectAttempts;
  final double averageLatency;

  SynchronizationDiagnostics copyWith({
    int? lastSequenceReceived,
    int? lastSnapshotVersion,
    int? pendingSnapshots,
    int? pendingEvents,
    int? reconnectAttempts,
    double? averageLatency,
  }) {
    return SynchronizationDiagnostics(
      lastSequenceReceived: lastSequenceReceived ?? this.lastSequenceReceived,
      lastSnapshotVersion: lastSnapshotVersion ?? this.lastSnapshotVersion,
      pendingSnapshots: pendingSnapshots ?? this.pendingSnapshots,
      pendingEvents: pendingEvents ?? this.pendingEvents,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      averageLatency: averageLatency ?? this.averageLatency,
    );
  }
}

/// Immutable state containing the complete LAN multiplayer snapshot.
class LANSession {
  const LANSession({
    this.room,
    required this.players,
    this.currentMatch,
    required this.canvasState,
    required this.connectionState,
    required this.networkStatistics,
    required this.connectionQuality,
    required this.synchronizationState,
    required this.sessionState,
    required this.diagnostics,
  });

  factory LANSession.initial() => LANSession(
    players: const [],
    canvasState: CanvasState.initial(),
    connectionState: NetworkConnectionState.disconnected,
    networkStatistics: const NetworkStatistics(),
    connectionQuality: ConnectionQuality.disconnected,
    synchronizationState: SynchronizationState.outOfSync,
    sessionState: LANSessionLifecycleState.discovering,
    diagnostics: SynchronizationDiagnostics.initial(),
  );

  final Room? room;
  final List<PlayerConnection> players;
  final Match? currentMatch;
  final CanvasState canvasState;
  final NetworkConnectionState connectionState;
  final NetworkStatistics networkStatistics;
  final ConnectionQuality connectionQuality;
  final SynchronizationState synchronizationState;
  final LANSessionLifecycleState sessionState;
  final SynchronizationDiagnostics diagnostics;

  LANSession copyWith({
    Room? Function()? room,
    List<PlayerConnection>? players,
    Match? Function()? currentMatch,
    CanvasState? canvasState,
    NetworkConnectionState? connectionState,
    NetworkStatistics? networkStatistics,
    ConnectionQuality? connectionQuality,
    SynchronizationState? synchronizationState,
    LANSessionLifecycleState? sessionState,
    SynchronizationDiagnostics? diagnostics,
  }) {
    return LANSession(
      room: room != null ? room() : this.room,
      players: players ?? this.players,
      currentMatch: currentMatch != null ? currentMatch() : this.currentMatch,
      canvasState: canvasState ?? this.canvasState,
      connectionState: connectionState ?? this.connectionState,
      networkStatistics: networkStatistics ?? this.networkStatistics,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      synchronizationState: synchronizationState ?? this.synchronizationState,
      sessionState: sessionState ?? this.sessionState,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }
}
