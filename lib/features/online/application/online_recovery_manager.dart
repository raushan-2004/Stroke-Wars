import 'dart:async';
import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/online/application/lobby_service.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';
import 'package:stroke_wars/features/multiplayer/domain/repositories/game_transport.dart';

/// Diagnostics record of session reconnects.
class RecoveryDiagnostics {
  const RecoveryDiagnostics({
    required this.reconnectCount,
    required this.lastIssue,
    required this.restorationSuccessful,
  });

  final int reconnectCount;
  final String lastIssue;
  final bool restorationSuccessful;
}

/// Service owning the reconnect recovery loop, lobby restoration,
/// and replaying of buffered packets upon socket reconnects.
class OnlineRecoveryManager {
  OnlineRecoveryManager({
    required this.transport,
    required this.lobbyService,
    required this.onRecoveryStateChanged,
  });

  final WebSocketTransport transport;
  final LobbyService lobbyService;
  final void Function(bool isRestoring) onRecoveryStateChanged;

  int _reconnectAttempts = 0;
  String _lastIssue = 'None';
  bool _restorationSuccessful = false;

  RecoveryDiagnostics get diagnostics => RecoveryDiagnostics(
    reconnectCount: _reconnectAttempts,
    lastIssue: _lastIssue,
    restorationSuccessful: _restorationSuccessful,
  );

  /// Performs session reconnect and lobby restoration.
  Future<void> initiateRestoration({
    required String? lastSessionId,
    required OnlineLobby? lastLobby,
    required String address,
    required int port,
  }) async {
    if (lastSessionId == null || lastLobby == null) {
      _lastIssue = 'No active session or lobby to restore';
      return;
    }

    _reconnectAttempts++;
    onRecoveryStateChanged(true);
    AppLogger.instance.info(
      'OnlineRecoveryManager initiating restoration for session: $lastSessionId',
    );

    try {
      // Re-establish connection
      await transport.connect(address, port);

      // Wait brief time to verify connection state
      int retries = 0;
      while (transport.currentState == TransportConnectionState.connecting &&
          retries < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }

      if (transport.currentState == TransportConnectionState.connected) {
        // Restore lobby
        await lobbyService.joinLobby(lastLobby.id, lastLobby.privateCode);
        _restorationSuccessful = true;
        AppLogger.instance.info(
          'OnlineRecoveryManager successfully restored lobby: ${lastLobby.name}',
        );
      } else {
        _lastIssue = 'Socket reconnect failed';
        _restorationSuccessful = false;
      }
    } catch (e) {
      _lastIssue = 'Restoration error: $e';
      _restorationSuccessful = false;
      AppLogger.instance.error('OnlineRecoveryManager restoration failed: $e');
    } finally {
      onRecoveryStateChanged(false);
    }
  }

  void reset() {
    _reconnectAttempts = 0;
    _lastIssue = 'None';
    _restorationSuccessful = false;
  }
}
