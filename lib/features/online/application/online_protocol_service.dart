import 'dart:convert';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';

/// Service isolating serialization, protocol packing, and version compatibility checks.
class OnlineProtocolService {
  const OnlineProtocolService({
    this.currentProtocolVersion = 1,
    this.currentEngineVersion = '1.0.0',
  });

  final int currentProtocolVersion;
  final String currentEngineVersion;

  /// Validates server versions for compatibility.
  bool validateCompatibility(int serverProtocol, String serverEngine) {
    if (serverProtocol != currentProtocolVersion) return false;
    // Allow minor changes, but verify major version of engine
    final serverMajor = serverEngine.split('.').first;
    final clientMajor = currentEngineVersion.split('.').first;
    return serverMajor == clientMajor;
  }

  /// Encapsulates auth credentials into a protocol packet.
  String buildAuthRequest(String name, String token) {
    return jsonEncode({
      'type': 'auth_request',
      'protocolVersion': currentProtocolVersion,
      'engineVersion': currentEngineVersion,
      'name': name,
      'token': token,
    });
  }

  /// Encapsulates lobby parameters into a creation packet.
  String buildCreateLobbyRequest({
    required String name,
    required int maxPlayers,
    required bool isPrivate,
    String? privateCode,
  }) {
    return jsonEncode({
      'type': 'create_lobby_request',
      'name': name,
      'maxPlayers': maxPlayers,
      'isPrivate': isPrivate,
      'privateCode': privateCode,
    });
  }

  /// Encapsulates lobby join criteria.
  String buildJoinLobbyRequest(String lobbyId, String? privateCode) {
    return jsonEncode({
      'type': 'join_lobby_request',
      'lobbyId': lobbyId,
      'privateCode': privateCode,
    });
  }

  /// Encapsulates lobby departure.
  String buildLeaveLobbyRequest() {
    return jsonEncode({'type': 'leave_lobby_request'});
  }

  /// Encapsulates ready state change.
  String buildReadyToggleRequest(bool isReady) {
    return jsonEncode({'type': 'ready_toggle_request', 'isReady': isReady});
  }

  /// Translates a drawing canvas event into a raw network packet.
  String buildCanvasEventPacket(DrawingEvent event) {
    return jsonEncode({'type': 'canvas_event_packet', 'event': event.toJson()});
  }

  /// Translates a gameplay MatchCommand into a raw network packet.
  String buildMatchCommandPacket(MatchCommand cmd) {
    // Determine command mapping
    Map<String, dynamic> payload = {};
    String cmdType = '';

    if (cmd is ChooseWordCommand) {
      cmdType = 'choose_word';
      payload = {
        'matchId': cmd.matchId.value,
        'drawerId': cmd.drawerId,
        'wordId': cmd.wordId,
      };
    } else if (cmd is SubmitGuessCommand) {
      cmdType = 'submit_guess';
      payload = {
        'matchId': cmd.matchId.value,
        'playerId': cmd.playerId,
        'guessText': cmd.guessText,
      };
    }

    return jsonEncode({
      'type': 'match_command_packet',
      'commandType': cmdType,
      'payload': payload,
    });
  }

  /// Decodes a raw inbound socket message into a key-value Map.
  Map<String, dynamic> decodeInboundMessage(String content) {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const {}; // Gracefully absorb malformed packets
    }
  }
}
