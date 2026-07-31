import 'package:stroke_wars/features/live_services/domain/models/live_services_models.dart';
import 'package:stroke_wars/features/live_services/domain/repositories/cloud_storage.dart';

/// In-memory mock cloud storage implementing [CloudStorage].
///
/// Features artificial lag, connection failure toggles, and malformed payload options.
class MockCloudStorage implements CloudStorage {
  final Map<String, Map<String, dynamic>> _profiles = {};
  final List<Map<String, dynamic>> _matchSummaries = [];

  bool simulateFailure = false;
  bool simulateMalformedResponse = false;

  @override
  CloudCapabilities get capabilities => const CloudCapabilities(
    profileSync: true,
    replaySync: true,
    leaderboards: true,
    announcements: true,
    remoteConfig: true,
    compression: false,
    maximumReplaySize: 2 * 1024 * 1024, // 2MB
  );

  @override
  Future<void> uploadProfile(String userId, Map<String, dynamic> data) async {
    await _checkNetwork();
    _profiles[userId] = Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> downloadProfile(String userId) async {
    await _checkNetwork();
    if (simulateMalformedResponse) {
      return {'corruptKey': 'brokenValue'};
    }
    return _profiles[userId];
  }

  @override
  Future<void> uploadMatchSummary(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _checkNetwork();
    _matchSummaries.add(data);
  }

  @override
  Future<LiveConfig> fetchLiveConfig() async {
    await _checkNetwork();
    if (simulateMalformedResponse) {
      throw const FormatException('Malformed config response');
    }
    return LiveConfig(
      xpMultiplier: 1.5,
      seasonName: 'Season 1: Genesis',
      seasonEnd: DateTime.now().add(const Duration(days: 30)),
      featuredModes: const ['classic', 'speedrun'],
      maintenanceMessage: null,
      announcements: [
        Announcement(
          title: 'Welcome to Stage 10!',
          body: 'Enjoy Backend and cloud synchronizations.',
          type: AnnouncementType.news,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> _checkNetwork() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (simulateFailure) {
      throw Exception('Network connection timed out');
    }
  }

  /// Helper to seed data during test setups.
  void forceSetProfile(String userId, Map<String, dynamic> data) {
    _profiles[userId] = data;
  }
}
