import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';

/// Abstract storage provider interface ensuring backend-independence.
abstract interface class CloudStorage {
  /// Defines capabilities specific to this backend engine.
  CloudCapabilities get capabilities;

  /// Uploads profile state map to the remote server.
  Future<void> uploadProfile(String userId, Map<String, dynamic> data);

  /// Downloads profile state map from the remote server.
  Future<Map<String, dynamic>?> downloadProfile(String userId);

  /// Uploads match summaries / stats to the remote server.
  Future<void> uploadMatchSummary(String userId, Map<String, dynamic> data);

  /// Fetches the remote config including announcements.
  Future<LiveConfig> fetchLiveConfig();
}
