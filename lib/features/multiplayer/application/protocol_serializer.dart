import 'dart:convert';

import 'package:stroke_wars/features/multiplayer/domain/protocol/network_envelope.dart';
import 'package:stroke_wars/features/multiplayer/domain/protocol/network_message.dart';

/// The single serialization boundary responsible for encoding/decoding network envelopes and payloads.
class ProtocolSerializer {
  ProtocolSerializer({
    this.currentProtocolVersion = 1,
    this.currentEngineVersion = '1.0.0',
  });

  /// The active protocol version supported by this serializer instance.
  final int currentProtocolVersion;

  /// The active game engine version supported by this serializer instance.
  final String currentEngineVersion;

  /// Encodes a [NetworkEnvelope] into a JSON String.
  String encode(NetworkEnvelope envelope) {
    return jsonEncode(envelope.toJson());
  }

  /// Decodes a raw JSON string into a [NetworkEnvelope].
  ///
  /// Throws [FormatException] if the packet is malformed.
  NetworkEnvelope decode(String rawJson) {
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;
    return NetworkEnvelope.fromJson(data);
  }

  /// Validates envelope version headers against current capabilities.
  ///
  /// Returns null if valid, or a descriptive String reason if invalid.
  String? validateVersions(NetworkEnvelope envelope) {
    if (envelope.protocolVersion != currentProtocolVersion) {
      return 'Protocol version mismatch: expected $currentProtocolVersion, got ${envelope.protocolVersion}';
    }
    // We can also check engine compatibility if strict version matching is required.
    if (envelope.engineVersion != currentEngineVersion) {
      return 'Engine version mismatch: expected $currentEngineVersion, got ${envelope.engineVersion}';
    }
    return null;
  }

  /// Reconstructs a concrete [NetworkMessage] payload from the envelope.
  ///
  /// Returns the parsed message, or throws [ArgumentError] if the payload type is unknown or invalid.
  NetworkMessage decodePayload(NetworkEnvelope envelope) {
    final type = envelope.payloadType;
    final payloadData = envelope.payload;

    switch (type) {
      case 'version':
        return VersionMessage.fromJson(payloadData);
      case 'join_room':
        return JoinRoomMessage.fromJson(payloadData);
      case 'leave_room':
        return LeaveRoomMessage.fromJson(payloadData);
      case 'ready':
        return ReadyMessage.fromJson(payloadData);
      case 'match_command':
        return MatchCommandMessage.fromJson(payloadData);
      case 'match_event':
        return MatchEventMessage.fromJson(payloadData);
      case 'canvas_event':
        return CanvasEventMessage.fromJson(payloadData);
      case 'heartbeat':
        return HeartbeatMessage.fromJson(payloadData);
      case 'ping':
        return PingMessage.fromJson(payloadData);
      case 'pong':
        return PongMessage.fromJson(payloadData);
      case 'snapshot':
        return SnapshotMessage.fromJson(payloadData);
      case 'error':
        return ErrorMessage.fromJson(payloadData);
      default:
        throw ArgumentError('Unsupported payload type: $type');
    }
  }
}
