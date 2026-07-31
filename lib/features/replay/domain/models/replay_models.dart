import 'dart:convert';

/// Unique replay identifier.
class ReplayId {
  final String value;
  const ReplayId(this.value);

  @override
  bool operator ==(Object other) => other is ReplayId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// The state of the replay player.
enum PlaybackState { loading, ready, playing, paused, seeking, finished }

/// Validates replay integrity, checking protocol/engine compatibility and checksums.
class ReplayIntegrity {
  final int replayVersion;
  final String engineVersion;
  final int protocolVersion;
  final String checksum;

  const ReplayIntegrity({
    required this.replayVersion,
    required this.engineVersion,
    required this.protocolVersion,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'replayVersion': replayVersion,
    'engineVersion': engineVersion,
    'protocolVersion': protocolVersion,
    'checksum': checksum,
  };

  factory ReplayIntegrity.fromJson(Map<String, dynamic> json) =>
      ReplayIntegrity(
        replayVersion: json['replayVersion'] as int? ?? 1,
        engineVersion: json['engineVersion'] as String? ?? '1.0.0',
        protocolVersion: json['protocolVersion'] as int? ?? 1,
        checksum: json['checksum'] as String? ?? '',
      );
}

/// Metadata stored inside a replay header.
class ReplayMetadata {
  final DateTime matchStartTime;
  final DateTime matchEndTime;
  final Duration duration;
  final String winner;
  final Map<String, int> finalScores;
  final List<String> playerList;
  final String gameMode;
  final ReplayIntegrity integrity;

  const ReplayMetadata({
    required this.matchStartTime,
    required this.matchEndTime,
    required this.duration,
    required this.winner,
    required this.finalScores,
    required this.playerList,
    required this.gameMode,
    required this.integrity,
  });

  Map<String, dynamic> toJson() => {
    'matchStartTime': matchStartTime.toIso8601String(),
    'matchEndTime': matchEndTime.toIso8601String(),
    'durationMs': duration.inMilliseconds,
    'winner': winner,
    'finalScores': finalScores,
    'playerList': playerList,
    'gameMode': gameMode,
    'integrity': integrity.toJson(),
  };

  factory ReplayMetadata.fromJson(Map<String, dynamic> json) => ReplayMetadata(
    matchStartTime: DateTime.parse(json['matchStartTime'] as String),
    matchEndTime: DateTime.parse(json['matchEndTime'] as String),
    duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
    winner: json['winner'] as String? ?? '',
    finalScores: Map<String, int>.from(json['finalScores'] as Map? ?? {}),
    playerList: List<String>.from(json['playerList'] as List? ?? []),
    gameMode: json['gameMode'] as String? ?? 'offline',
    integrity: ReplayIntegrity.fromJson(
      json['integrity'] as Map<String, dynamic>,
    ),
  );
}

/// A serialized gameplay event.
class ReplayEvent {
  final int sequenceNumber;
  final int timestampOffsetMs;
  final String type; // 'match', 'drawing', 'chat'
  final Map<String, dynamic> payload;

  const ReplayEvent({
    required this.sequenceNumber,
    required this.timestampOffsetMs,
    required this.type,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
    'sequenceNumber': sequenceNumber,
    'timestampOffsetMs': timestampOffsetMs,
    'type': type,
    'payload': payload,
  };

  factory ReplayEvent.fromJson(Map<String, dynamic> json) => ReplayEvent(
    sequenceNumber: json['sequenceNumber'] as int,
    timestampOffsetMs: json['timestampOffsetMs'] as int,
    type: json['type'] as String,
    payload: json['payload'] as Map<String, dynamic>,
  );
}

/// Holds the list of ordered replay events, kept separate from the session for lazy loading.
class ReplayEventLog {
  final List<ReplayEvent> events;
  const ReplayEventLog({required this.events});

  Map<String, dynamic> toJson() => {
    'events': events.map((e) => e.toJson()).toList(),
  };

  factory ReplayEventLog.fromJson(Map<String, dynamic> json) {
    final list = json['events'] as List? ?? [];
    return ReplayEventLog(
      events: list
          .map((e) => ReplayEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A checkpoint for fast seeking.
class ReplayCheckpoint {
  final int sequenceNumber;
  final int timestampOffsetMs;
  final Map<String, dynamic> matchStateJson;
  final List<Map<String, dynamic>> drawingEventsJson;
  final Map<String, int> scoreboard;
  final int roundNumber;

  const ReplayCheckpoint({
    required this.sequenceNumber,
    required this.timestampOffsetMs,
    required this.matchStateJson,
    required this.drawingEventsJson,
    required this.scoreboard,
    required this.roundNumber,
  });

  Map<String, dynamic> toJson() => {
    'sequenceNumber': sequenceNumber,
    'timestampOffsetMs': timestampOffsetMs,
    'matchStateJson': matchStateJson,
    'drawingEventsJson': drawingEventsJson,
    'scoreboard': scoreboard,
    'roundNumber': roundNumber,
  };

  factory ReplayCheckpoint.fromJson(Map<String, dynamic> json) =>
      ReplayCheckpoint(
        sequenceNumber: json['sequenceNumber'] as int,
        timestampOffsetMs: json['timestampOffsetMs'] as int,
        matchStateJson: json['matchStateJson'] as Map<String, dynamic>? ?? {},
        drawingEventsJson: (json['drawingEventsJson'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        scoreboard: Map<String, int>.from(json['scoreboard'] as Map? ?? {}),
        roundNumber: json['roundNumber'] as int? ?? 1,
      );
}

/// Auto-generated or manual markers on the timeline.
class Bookmark {
  final String title;
  final int timestampOffsetMs;
  final String description;

  const Bookmark({
    required this.title,
    required this.timestampOffsetMs,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'timestampOffsetMs': timestampOffsetMs,
    'description': description,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    title: json['title'] as String,
    timestampOffsetMs: json['timestampOffsetMs'] as int,
    description: json['description'] as String? ?? '',
  );
}

/// Replay Session state.
class ReplaySession {
  final ReplayId replayId;
  final String matchId;
  final List<String> players;
  final ReplayMetadata metadata;
  final int currentFrame;
  final PlaybackState playbackState;
  final double playbackSpeed;
  final Duration duration;
  final List<Bookmark> bookmarks;

  const ReplaySession({
    required this.replayId,
    required this.matchId,
    required this.players,
    required this.metadata,
    required this.currentFrame,
    required this.playbackState,
    required this.playbackSpeed,
    required this.duration,
    required this.bookmarks,
  });

  ReplaySession copyWith({
    ReplayId? replayId,
    String? matchId,
    List<String>? players,
    ReplayMetadata? metadata,
    int? currentFrame,
    PlaybackState? playbackState,
    double? playbackSpeed,
    Duration? duration,
    List<Bookmark>? bookmarks,
  }) {
    return ReplaySession(
      replayId: replayId ?? this.replayId,
      matchId: matchId ?? this.matchId,
      players: players ?? this.players,
      metadata: metadata ?? this.metadata,
      currentFrame: currentFrame ?? this.currentFrame,
      playbackState: playbackState ?? this.playbackState,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      duration: duration ?? this.duration,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
