import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';

/// Manages the local persistent task queue for offline requests.
///
/// Features FIFO policy, deduplication, task expiry, and queue limit caps.
class OfflineCacheManager {
  OfflineCacheManager({this.maxQueueSize = 50, this.taskExpirationHours = 24});

  final int maxQueueSize;
  final int taskExpirationHours;
  final List<OfflineTask> _queue = [];

  Future<File> _getQueueFile() async {
    final docDir = await getApplicationDocumentsDirectory();
    final file = File('${docDir.path}/offline_queue.json');
    if (!await file.exists()) {
      await file.writeAsString(jsonEncode(<dynamic>[]));
    }
    return file;
  }

  /// Loads tasks from local disk cache.
  Future<List<OfflineTask>> loadTasks() async {
    try {
      final file = await _getQueueFile();
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as List? ?? [];
      _queue.clear();
      _queue.addAll(
        decoded
            .map((item) => OfflineTask.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      _pruneExpiredTasks();
      return List.unmodifiable(_queue);
    } catch (_) {
      return [];
    }
  }

  /// Appends a new task. Handles deduplication and maximum queue limit.
  Future<void> enqueueTask(OfflineTask task) async {
    await loadTasks();

    // 1. Deduplication: If we queue a new profile or stats upload, remove older pending uploads of the same type!
    if (task.type == OfflineTaskType.uploadProfile ||
        task.type == OfflineTaskType.uploadStats) {
      _queue.removeWhere((t) => t.type == task.type);
    }

    // 2. Queue capacity check
    if (_queue.length >= maxQueueSize) {
      // FIFO Policy: Discard oldest task
      _queue.removeAt(0);
    }

    _queue.add(task);
    await _saveQueue();
  }

  /// Removes a task from the queue.
  Future<void> dequeueTask(String taskId) async {
    _queue.removeWhere((t) => t.id == taskId);
    await _saveQueue();
  }

  /// Clears all tasks.
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
  }

  Future<void> _saveQueue() async {
    final file = await _getQueueFile();
    final jsonList = _queue.map((t) => t.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  void _pruneExpiredTasks() {
    final now = DateTime.now();
    _queue.removeWhere((task) {
      final age = now.difference(task.createdAt);
      return age.inHours >= taskExpirationHours;
    });
  }

  /// Increases retry counter for a task.
  Future<void> incrementRetry(String taskId) async {
    final index = _queue.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _queue[index];
      _queue[index] = task.copyWith(retryCount: task.retryCount + 1);
      await _saveQueue();
    }
  }
}
