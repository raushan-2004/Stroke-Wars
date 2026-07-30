import 'dart:async';
import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';

/// Decoupled manager responsible for sequence ordering, duplicate checking,
/// active drawer validation, and late-join/reconnect snapshot sync.
class SynchronizationManager {
  SynchronizationManager({
    required this.matchController,
    required this.canvasController,
    required this.onStateChanged,
  });

  final MatchController matchController;
  final CanvasController canvasController;
  final void Function(
    SynchronizationState state,
    SynchronizationDiagnostics diagnostics,
  )
  onStateChanged;

  int _lastSequenceReceived = 0;
  int _lastSnapshotVersion = 0;
  int _pendingSnapshots = 0;
  int _pendingEvents = 0;
  int _reconnectAttempts = 0;
  double _averageLatency = 0.0;
  SynchronizationState _syncState = SynchronizationState.outOfSync;

  /// Resets internal sequencing markers (e.g. on new hosting/joining session)
  void reset() {
    _lastSequenceReceived = 0;
    _lastSnapshotVersion = 0;
    _pendingSnapshots = 0;
    _pendingEvents = 0;
    _reconnectAttempts = 0;
    _averageLatency = 0.0;
    _syncState = SynchronizationState.outOfSync;
    _updateState();
  }

  /// Sets the current reconnection attempts.
  void setReconnectAttempts(int attempts) {
    _reconnectAttempts = attempts;
    if (attempts > 0) {
      _syncState = SynchronizationState.recovering;
    }
    _updateState();
  }

  /// Sets the latency.
  void updateLatency(double latencyMs) {
    _averageLatency = latencyMs;
    _updateState();
  }

  /// Processes inbound network envelopes authoritatively or mirror-side.
  bool processInboundEnvelope({
    required NetworkEnvelope envelope,
    required NetworkMessage message,
    required bool isHost,
    required String? activeDrawerId,
    required List<String> roomPlayerIds,
    required Map<String, String> connectionIdToPlayerIdMap,
  }) {
    _pendingEvents++;

    // 1. Sequence validation / Duplicate filtering
    if (envelope.sequenceNumber <= _lastSequenceReceived &&
        message is! SnapshotMessage) {
      AppLogger.instance.warning(
        'SynchronizationManager: Dropped duplicate/out-of-order packet (seq=${envelope.sequenceNumber}, expected > $_lastSequenceReceived)',
      );
      _pendingEvents--;
      return false; // Discarded
    }
    _lastSequenceReceived = envelope.sequenceNumber;

    // 2. Active Drawer validation (Host authority only)
    if (isHost && message is CanvasEventMessage) {
      final senderConnId = envelope.connectionId.value;
      final senderPlayerId = connectionIdToPlayerIdMap[senderConnId];

      if (senderPlayerId != activeDrawerId) {
        AppLogger.instance.warning(
          'SynchronizationManager: Rejected unauthorized drawing event from sender "$senderPlayerId" (conn ID "$senderConnId") when active drawer is "$activeDrawerId"',
        );
        _pendingEvents--;
        return false; // Discarded: Not active drawer
      }
    }

    // 3. Process Snapshots / Sync points
    if (message is SnapshotMessage) {
      final snapshot = message.snapshot;
      _pendingSnapshots++;

      if (snapshot.sequenceNumber < _lastSnapshotVersion) {
        // Stale snapshot, discard
        _pendingSnapshots--;
        _pendingEvents--;
        return false;
      }
      _lastSnapshotVersion = snapshot.sequenceNumber;
      _syncState = SynchronizationState.synchronizing;
      _updateState();

      // Defer recovery state change
      _pendingSnapshots--;
      _syncState = SynchronizationState.synchronized;
    }

    _pendingEvents--;
    _syncState = SynchronizationState.synchronized;
    _updateState();
    return true; // Allowed
  }

  void forceOutOfSync() {
    _syncState = SynchronizationState.outOfSync;
    _updateState();
  }

  void _updateState() {
    onStateChanged(
      _syncState,
      SynchronizationDiagnostics(
        lastSequenceReceived: _lastSequenceReceived,
        lastSnapshotVersion: _lastSnapshotVersion,
        pendingSnapshots: _pendingSnapshots,
        pendingEvents: _pendingEvents,
        reconnectAttempts: _reconnectAttempts,
        averageLatency: _averageLatency,
      ),
    );
  }
}
