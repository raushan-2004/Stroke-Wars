import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';

/// Represents a generic network message wrapper providing protocol metadata, sequencing, and payload encapsulation.
class NetworkEnvelope {
  const NetworkEnvelope({
    required this.messageId,
    required this.sessionId,
    required this.connectionId,
    required this.protocolVersion,
    required this.engineVersion,
    required this.sequenceNumber,
    required this.acknowledgementNumber,
    required this.timestamp,
    required this.payloadType,
    required this.payload,
  });

  /// Unique message ID for drop/duplicate checks.
  final MessageId messageId;

  /// Unique session UUID of the match room.
  final SessionId sessionId;

  /// Unique network connection UUID/identifier.
  final ConnectionId connectionId;

  /// Schema version code.
  final int protocolVersion;

  /// Application version tag (e.g. "1.0.0").
  final String engineVersion;

  /// Outbound sequence counter for order verification.
  final int sequenceNumber;

  /// Outbound acknowledgment sequence tracker.
  final int acknowledgementNumber;

  /// Transmission timestamp.
  final DateTime timestamp;

  /// String descriptor matching [NetworkMessage.type].
  final String payloadType;

  /// Raw JSON payload map of the inner message.
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'messageId': messageId.value,
        'sessionId': sessionId.value,
        'connectionId': connectionId.value,
        'protocolVersion': protocolVersion,
        'engineVersion': engineVersion,
        'sequenceNumber': sequenceNumber,
        'acknowledgementNumber': acknowledgementNumber,
        'timestamp': timestamp.toIso8601String(),
        'payloadType': payloadType,
        'payload': payload,
      };

  factory NetworkEnvelope.fromJson(Map<String, dynamic> json) => NetworkEnvelope(
        messageId: MessageId(json['messageId'] as String),
        sessionId: SessionId(json['sessionId'] as String),
        connectionId: ConnectionId(json['connectionId'] as String),
        protocolVersion: json['protocolVersion'] as int,
        engineVersion: json['engineVersion'] as String,
        sequenceNumber: json['sequenceNumber'] as int,
        acknowledgementNumber: json['acknowledgementNumber'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        payloadType: json['payloadType'] as String,
        payload: json['payload'] as Map<String, dynamic>,
      );
}
