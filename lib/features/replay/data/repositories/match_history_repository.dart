import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stroke_wars/features/profile/domain/models/match_history.dart';

/// Repository responsible for maintaining match history independently of active replay sessions.
class MatchHistoryRepository {
  Future<File> _getHistoryFile() async {
    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/match_history.json');
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode(<dynamic>[]));
    }
    return file;
  }

  /// Lists all completed match history records, sorted by playedAt descending.
  Future<List<MatchHistory>> getMatchHistory() async {
    try {
      final file = await _getHistoryFile();
      final content = await file.readAsString();
      final list = jsonDecode(content) as List? ?? [];
      final historyList = list
          .map((item) => MatchHistory.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort by newest played match first
      historyList.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      return historyList;
    } catch (_) {
      return [];
    }
  }

  /// Appends a new completed MatchHistory entry to history.
  Future<void> addMatchRecord(MatchHistory record) async {
    final history = await getMatchHistory();
    // Prevent duplicate entries
    if (history.any((h) => h.matchId == record.matchId)) return;

    history.add(record);
    final file = await _getHistoryFile();
    final jsonList = history.map((h) => h.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Clears the match history file completely.
  Future<void> clearHistory() async {
    final file = await _getHistoryFile();
    await file.writeAsString(jsonEncode(<dynamic>[]));
  }
}
