import 'dart:convert';
import 'package:stroke_wars/features/replay/domain/models/replay_models.dart';

/// Serialization helper isolating JSON framing, checksum calculation, and version checks.
class ReplaySerializer {
  /// Encodes metadata, event log, checkpoints, and bookmarks into a unified JSON string.
  String encodeReplay({
    required ReplayMetadata metadata,
    required ReplayEventLog eventLog,
    required List<ReplayCheckpoint> checkpoints,
    required List<Bookmark> bookmarks,
  }) {
    final Map<String, dynamic> rawPayload = {
      'eventLog': eventLog.toJson(),
      'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    };

    final payloadString = jsonEncode(rawPayload);
    final checksum = _calculateChecksum(payloadString);

    final integrity = ReplayIntegrity(
      replayVersion: metadata.integrity.replayVersion,
      engineVersion: metadata.integrity.engineVersion,
      protocolVersion: metadata.integrity.protocolVersion,
      checksum: checksum,
    );

    final finalMetadata = ReplayMetadata(
      matchStartTime: metadata.matchStartTime,
      matchEndTime: metadata.matchEndTime,
      duration: metadata.duration,
      winner: metadata.winner,
      finalScores: metadata.finalScores,
      playerList: metadata.playerList,
      gameMode: metadata.gameMode,
      integrity: integrity,
    );

    final Map<String, dynamic> root = {
      'metadata': finalMetadata.toJson(),
      'payload': rawPayload,
    };

    return jsonEncode(root);
  }

  /// Decodes and validates a replay JSON string.
  ///
  /// Throws [FormatException] if integrity check fails or version is incompatible.
  Map<String, dynamic> decodeReplay(String jsonStr) {
    final root = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (!root.containsKey('metadata') || !root.containsKey('payload')) {
      throw const FormatException('Corrupted Replay: Missing root elements');
    }

    final metadata = ReplayMetadata.fromJson(
      root['metadata'] as Map<String, dynamic>,
    );
    final payload = root['payload'] as Map<String, dynamic>;

    // 1. Version validation
    if (metadata.integrity.replayVersion > 1) {
      throw FormatException(
        'Incompatible Replay version: Supported <= 1, got ${metadata.integrity.replayVersion}',
      );
    }

    // 2. Checksum validation
    final payloadString = jsonEncode(payload);
    final calculatedChecksum = _calculateChecksum(payloadString);
    if (calculatedChecksum != metadata.integrity.checksum) {
      throw const FormatException('Corrupted Replay: Checksum mismatch');
    }

    final eventLog = ReplayEventLog.fromJson(
      payload['eventLog'] as Map<String, dynamic>,
    );
    final checkpoints = (payload['checkpoints'] as List? ?? [])
        .map((c) => ReplayCheckpoint.fromJson(c as Map<String, dynamic>))
        .toList();
    final bookmarks = (payload['bookmarks'] as List? ?? [])
        .map((b) => Bookmark.fromJson(b as Map<String, dynamic>))
        .toList();

    return {
      'metadata': metadata,
      'eventLog': eventLog,
      'checkpoints': checkpoints,
      'bookmarks': bookmarks,
    };
  }

  /// Partially decodes ONLY the metadata portion of the replay JSON for quick history list loading.
  ReplayMetadata decodeMetadataOnly(String jsonStr) {
    final root = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (!root.containsKey('metadata')) {
      throw const FormatException('Corrupted Replay: Missing metadata');
    }
    return ReplayMetadata.fromJson(root['metadata'] as Map<String, dynamic>);
  }

  String _calculateChecksum(String content) {
    int hash = 0;
    for (int i = 0; i < content.length; i++) {
      hash = (31 * hash + content.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
