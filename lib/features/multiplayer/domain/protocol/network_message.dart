import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/domain/commands/match_command.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match_id.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/peer_info.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/room_snapshot.dart';

/// Base class for all network message payloads.
sealed class NetworkMessage {
  const NetworkMessage();

  /// The machine-readable string key identifying this payload's type.
  String get type;

  /// Converts the payload properties into a JSON map.
  Map<String, dynamic> toJson();
}

/// Client handshake request verifying protocol and engine compatibility.
class VersionMessage extends NetworkMessage {
  const VersionMessage({
    required this.protocolVersion,
    required this.engineVersion,
  });

  final int protocolVersion;
  final String engineVersion;

  @override
  String get type => 'version';

  @override
  Map<String, dynamic> toJson() => {
    'protocolVersion': protocolVersion,
    'engineVersion': engineVersion,
  };

  factory VersionMessage.fromJson(Map<String, dynamic> json) => VersionMessage(
    protocolVersion: json['protocolVersion'] as int,
    engineVersion: json['engineVersion'] as String,
  );
}

/// Client request payload to join a multiplayer room lobby.
class JoinRoomMessage extends NetworkMessage {
  const JoinRoomMessage({required this.peerInfo});

  final PeerInfo peerInfo;

  @override
  String get type => 'join_room';

  @override
  Map<String, dynamic> toJson() => {'peerInfo': peerInfo.toJson()};

  factory JoinRoomMessage.fromJson(Map<String, dynamic> json) =>
      JoinRoomMessage(
        peerInfo: PeerInfo.fromJson(json['peerInfo'] as Map<String, dynamic>),
      );
}

/// Broadcast payload notifying players that a peer has left, or kicked.
class LeaveRoomMessage extends NetworkMessage {
  const LeaveRoomMessage({required this.peerId, required this.reason});

  final String peerId;
  final String reason;

  @override
  String get type => 'leave_room';

  @override
  Map<String, dynamic> toJson() => {'peerId': peerId, 'reason': reason};

  factory LeaveRoomMessage.fromJson(Map<String, dynamic> json) =>
      LeaveRoomMessage(
        peerId: json['peerId'] as String,
        reason: json['reason'] as String,
      );
}

/// Client payload indicating readiness status to start the match.
class ReadyMessage extends NetworkMessage {
  const ReadyMessage({required this.peerId, required this.isReady});

  final String peerId;
  final bool isReady;

  @override
  String get type => 'ready';

  @override
  Map<String, dynamic> toJson() => {'peerId': peerId, 'isReady': isReady};

  factory ReadyMessage.fromJson(Map<String, dynamic> json) => ReadyMessage(
    peerId: json['peerId'] as String,
    isReady: json['isReady'] as bool,
  );
}

/// Client request sending a match command to the authoritative host.
class MatchCommandMessage extends NetworkMessage {
  const MatchCommandMessage({required this.command});

  final MatchCommand command;

  @override
  String get type => 'match_command';

  @override
  Map<String, dynamic> toJson() {
    // Note: To serialize MatchCommand properly, we can output its class name or map it.
    // However, MatchCommand has no built-in toJson. Let's serialize its type and fields.
    return {
      'commandType': command.runtimeType.toString(),
      'commandData': _serializeCommand(command),
    };
  }

  factory MatchCommandMessage.fromJson(Map<String, dynamic> json) =>
      MatchCommandMessage(
        command: _deserializeCommand(
          json['commandType'] as String,
          json['commandData'] as Map<String, dynamic>,
        ),
      );
}

/// Host broadcast distributing an authoritative gameplay event to clients.
class MatchEventMessage extends NetworkMessage {
  const MatchEventMessage({required this.event});

  final MatchEvent event;

  @override
  String get type => 'match_event';

  @override
  Map<String, dynamic> toJson() => {'event': event.toJson()};

  factory MatchEventMessage.fromJson(Map<String, dynamic> json) =>
      MatchEventMessage(
        event: MatchEvent.fromJson(json['event'] as Map<String, dynamic>),
      );
}

/// Client or Host drawing canvas event broadcast payload.
class CanvasEventMessage extends NetworkMessage {
  const CanvasEventMessage({required this.event});

  final DrawingEvent event;

  @override
  String get type => 'canvas_event';

  @override
  Map<String, dynamic> toJson() => {'event': event.toJson()};

  factory CanvasEventMessage.fromJson(Map<String, dynamic> json) =>
      CanvasEventMessage(
        event: DrawingEvent.fromJson(json['event'] as Map<String, dynamic>),
      );
}

/// Scheduled heartbeat connection keep-alive payload.
class HeartbeatMessage extends NetworkMessage {
  const HeartbeatMessage({required this.sentAt});

  final DateTime sentAt;

  @override
  String get type => 'heartbeat';

  @override
  Map<String, dynamic> toJson() => {'sentAt': sentAt.toIso8601String()};

  factory HeartbeatMessage.fromJson(Map<String, dynamic> json) =>
      HeartbeatMessage(sentAt: DateTime.parse(json['sentAt'] as String));
}

/// Latency measuring Ping request.
class PingMessage extends NetworkMessage {
  const PingMessage({required this.sentAt});

  final DateTime sentAt;

  @override
  String get type => 'ping';

  @override
  Map<String, dynamic> toJson() => {'sentAt': sentAt.toIso8601String()};

  factory PingMessage.fromJson(Map<String, dynamic> json) =>
      PingMessage(sentAt: DateTime.parse(json['sentAt'] as String));
}

/// Latency measuring Pong response.
class PongMessage extends NetworkMessage {
  const PongMessage({required this.pingSentAt, required this.sentAt});

  final DateTime pingSentAt;
  final DateTime sentAt;

  @override
  String get type => 'pong';

  @override
  Map<String, dynamic> toJson() => {
    'pingSentAt': pingSentAt.toIso8601String(),
    'sentAt': sentAt.toIso8601String(),
  };

  factory PongMessage.fromJson(Map<String, dynamic> json) => PongMessage(
    pingSentAt: DateTime.parse(json['pingSentAt'] as String),
    sentAt: DateTime.parse(json['sentAt'] as String),
  );
}

/// Full state snapshot payload used for reconnect and initial sync operations.
class SnapshotMessage extends NetworkMessage {
  const SnapshotMessage({required this.snapshot});

  final RoomSnapshot snapshot;

  @override
  String get type => 'snapshot';

  @override
  Map<String, dynamic> toJson() => {'snapshot': snapshot.toJson()};

  factory SnapshotMessage.fromJson(Map<String, dynamic> json) =>
      SnapshotMessage(
        snapshot: RoomSnapshot.fromJson(
          json['snapshot'] as Map<String, dynamic>,
        ),
      );
}

/// System error notification payload.
class ErrorMessage extends NetworkMessage {
  const ErrorMessage({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String get type => 'error';

  @override
  Map<String, dynamic> toJson() => {'code': code, 'message': message};

  factory ErrorMessage.fromJson(Map<String, dynamic> json) => ErrorMessage(
    code: json['code'] as String,
    message: json['message'] as String,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MatchCommand Manual Serialization Helpers
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _serializeCommand(MatchCommand cmd) {
  if (cmd is ChooseWordCommand) {
    return {
      'matchId': cmd.matchId.value,
      'drawerId': cmd.drawerId,
      'wordId': cmd.wordId,
    };
  } else if (cmd is SubmitGuessCommand) {
    return {
      'matchId': cmd.matchId.value,
      'playerId': cmd.playerId,
      'guessText': cmd.guessText,
    };
  } else if (cmd is ReadyPlayerCommand) {
    return {
      'matchId': cmd.matchId.value,
      'playerId': cmd.playerId,
      'isReady': cmd.isReady,
    };
  } else if (cmd is StartMatchCommand) {
    return {'matchId': cmd.matchId.value, 'hostId': cmd.hostId};
  } else if (cmd is LeaveMatchCommand) {
    return {'matchId': cmd.matchId.value, 'playerId': cmd.playerId};
  }
  return {};
}

MatchCommand _deserializeCommand(String type, Map<String, dynamic> data) {
  switch (type) {
    case 'ChooseWordCommand':
      return ChooseWordCommand(
        matchId: MatchId(data['matchId'] as String),
        drawerId: data['drawerId'] as String,
        wordId: data['wordId'] as String,
      );
    case 'SubmitGuessCommand':
      return SubmitGuessCommand(
        matchId: MatchId(data['matchId'] as String),
        playerId: data['playerId'] as String,
        guessText: data['guessText'] as String,
      );
    case 'ReadyPlayerCommand':
      return ReadyPlayerCommand(
        matchId: MatchId(data['matchId'] as String),
        playerId: data['playerId'] as String,
        isReady: data['isReady'] as bool,
      );
    case 'StartMatchCommand':
      return StartMatchCommand(
        matchId: MatchId(data['matchId'] as String),
        hostId: data['hostId'] as String,
      );
    case 'LeaveMatchCommand':
      return LeaveMatchCommand(
        matchId: MatchId(data['matchId'] as String),
        playerId: data['playerId'] as String,
      );
    default:
      return DummyMatchCommand(type);
  }
}
