import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Repository interacting with the file system to save, load, delete, and list replay JSON logs.
class ReplayRepository {
  Future<Directory> _getReplaysDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/replays');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Saves the serialized replay string to a file matching the replayId.
  Future<void> saveReplay(String replayId, String serializedJson) async {
    final dir = await _getReplaysDirectory();
    final file = File('${dir.path}/match_$replayId.json');
    await file.writeAsString(serializedJson);
  }

  /// Loads the serialized replay string from disk.
  Future<String> loadReplay(String replayId) async {
    final dir = await _getReplaysDirectory();
    final file = File('${dir.path}/match_$replayId.json');
    if (!await file.exists()) {
      throw FileSystemException('Replay file not found for ID: $replayId');
    }
    return await file.readAsString();
  }

  /// Deletes the replay file from disk.
  Future<void> deleteReplay(String replayId) async {
    final dir = await _getReplaysDirectory();
    final file = File('${dir.path}/match_$replayId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Lists all recorded replay files currently on disk.
  Future<List<String>> listReplays() async {
    final dir = await _getReplaysDirectory();
    final List<String> replayIds = [];
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        final filename = entity.uri.pathSegments.last;
        if (filename.startsWith('match_')) {
          final id = filename.replaceAll('match_', '').replaceAll('.json', '');
          replayIds.add(id);
        }
      }
    }
    return replayIds;
  }
}
