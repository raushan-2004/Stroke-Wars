import 'dart:async';
import 'dart:convert';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/player_connection.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';

/// Representation of a parsed online chat message.
class OnlineChatMessage {
  const OnlineChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
}

/// Router/Dispatcher translating raw network JSON messages into parsed domain events.
class ServerEventDispatcher {
  ServerEventDispatcher({
    required this.onMatchStateChanged,
    required this.onDrawingEventReceived,
    required this.onLobbyUpdated,
    required this.onChatMessageReceived,
    required this.onNotificationReceived,
  });

  final void Function(Map<String, dynamic> matchSnapshot) onMatchStateChanged;
  final void Function(DrawingEvent event) onDrawingEventReceived;
  final void Function(OnlineLobby lobby) onLobbyUpdated;
  final void Function(OnlineChatMessage msg) onChatMessageReceived;
  final void Function(String notification) onNotificationReceived;

  /// Dispatcher routes a parsed payload map.
  void dispatch(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'match_state_changed':
      case 'match_snapshot':
        final snapshot = payload['snapshot'] as Map<String, dynamic>?;
        if (snapshot != null) {
          onMatchStateChanged(snapshot);
        }
        break;

      case 'drawing_event':
        final eventJson = payload['event'] as Map<String, dynamic>?;
        if (eventJson != null) {
          try {
            final drawingEvent = DrawingEvent.fromJson(eventJson);
            onDrawingEventReceived(drawingEvent);
          } catch (_) {}
        }
        break;

      case 'lobby_update':
        final lobbyJson = payload['lobby'] as Map<String, dynamic>?;
        if (lobbyJson != null) {
          try {
            final lobby = OnlineLobby.fromJson(lobbyJson);
            onLobbyUpdated(lobby);
          } catch (_) {}
        }
        break;

      case 'chat_message':
        final msg = OnlineChatMessage(
          senderId: payload['senderId'] as String? ?? 'unknown',
          senderName: payload['senderName'] as String? ?? 'Anonymous',
          text: payload['text'] as String? ?? '',
          timestamp:
              DateTime.tryParse(payload['timestamp'] as String? ?? '') ??
              DateTime.now(),
        );
        onChatMessageReceived(msg);
        break;

      case 'server_notification':
        final text = payload['message'] as String? ?? '';
        onNotificationReceived(text);
        break;
    }
  }
}
