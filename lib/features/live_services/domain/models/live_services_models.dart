/// Immutable capability mapping for different Cloud Storage Backends.
class CloudCapabilities {
  final bool profileSync;
  final bool replaySync;
  final bool leaderboards;
  final bool announcements;
  final bool remoteConfig;
  final bool compression;
  final int maximumReplaySize;

  const CloudCapabilities({
    required this.profileSync,
    required this.replaySync,
    required this.leaderboards,
    required this.announcements,
    required this.remoteConfig,
    required this.compression,
    required this.maximumReplaySize,
  });

  Map<String, dynamic> toJson() => {
    'profileSync': profileSync,
    'replaySync': replaySync,
    'leaderboards': leaderboards,
    'announcements': announcements,
    'remoteConfig': remoteConfig,
    'compression': compression,
    'maximumReplaySize': maximumReplaySize,
  };
}

/// Define explicit conflict strategies when merging.
enum SyncConflictStrategy { localWins, cloudWins, merge, manualResolution }

class SyncConflict {
  final SyncConflictStrategy strategy;
  final String reason;

  const SyncConflict({required this.strategy, this.reason = ''});
}

/// States driving the cloud synchronization engine.
enum SyncStatus {
  idle,
  syncing,
  offline,
  retrying,
  conflict,
  completed,
  failed,
}

/// Rich Statistics mapped to the competitive cloud profile.
class CloudStatistics {
  final int games;
  final int wins;
  final int losses;
  final double guessAccuracy;
  final double averageDrawTime;
  final double averageGuessTime;
  final int highestStreak;
  final String mostUsedBrush;
  final Map<String, int> favoriteColors;

  const CloudStatistics({
    required this.games,
    required this.wins,
    required this.losses,
    required this.guessAccuracy,
    required this.averageDrawTime,
    required this.averageGuessTime,
    required this.highestStreak,
    required this.mostUsedBrush,
    required this.favoriteColors,
  });

  Map<String, dynamic> toJson() => {
    'games': games,
    'wins': wins,
    'losses': losses,
    'guessAccuracy': guessAccuracy,
    'averageDrawTime': averageDrawTime,
    'averageGuessTime': averageGuessTime,
    'highestStreak': highestStreak,
    'mostUsedBrush': mostUsedBrush,
    'favoriteColors': favoriteColors,
  };

  factory CloudStatistics.fromJson(Map<String, dynamic> json) =>
      CloudStatistics(
        games: json['games'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        guessAccuracy: (json['guessAccuracy'] as num? ?? 0.0).toDouble(),
        averageDrawTime: (json['averageDrawTime'] as num? ?? 0.0).toDouble(),
        averageGuessTime: (json['averageGuessTime'] as num? ?? 0.0).toDouble(),
        highestStreak: json['highestStreak'] as int? ?? 0,
        mostUsedBrush: json['mostUsedBrush'] as String? ?? 'classic',
        favoriteColors: Map<String, int>.from(
          json['favoriteColors'] as Map? ?? {},
        ),
      );
}

/// Cloud Aggregate Profile.
class CloudProfile {
  final String playerId;
  final String displayName;
  final String avatar;
  final CloudStatistics statistics;
  final List<String> achievements;
  final int xp;
  final int level;
  final List<String> cosmetics;
  final int cloudSaveVersion;

  const CloudProfile({
    required this.playerId,
    required this.displayName,
    required this.avatar,
    required this.statistics,
    required this.achievements,
    required this.xp,
    required this.level,
    required this.cosmetics,
    required this.cloudSaveVersion,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'displayName': displayName,
    'avatar': avatar,
    'statistics': statistics.toJson(),
    'achievements': achievements,
    'xp': xp,
    'level': level,
    'cosmetics': cosmetics,
    'cloudSaveVersion': cloudSaveVersion,
  };

  factory CloudProfile.fromJson(Map<String, dynamic> json) => CloudProfile(
    playerId: json['playerId'] as String,
    displayName: json['displayName'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    statistics: CloudStatistics.fromJson(
      json['statistics'] as Map<String, dynamic>? ?? {},
    ),
    achievements: List<String>.from(json['achievements'] as List? ?? []),
    xp: json['xp'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
    cosmetics: List<String>.from(json['cosmetics'] as List? ?? []),
    cloudSaveVersion: json['cloudSaveVersion'] as int? ?? 1,
  );
}

/// Type annotation for live broadcast announcements.
enum AnnouncementType { news, event, maintenance, patchNotes }

class Announcement {
  final String title;
  final String body;
  final AnnouncementType type;
  final DateTime timestamp;

  const Announcement({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    type: AnnouncementType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => AnnouncementType.news,
    ),
    timestamp: DateTime.parse(
      json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );
}

/// Remote configuration properties.
class LiveConfig {
  final double xpMultiplier;
  final String seasonName;
  final DateTime seasonEnd;
  final List<String> featuredModes;
  final String? maintenanceMessage;
  final List<Announcement> announcements;

  const LiveConfig({
    required this.xpMultiplier,
    required this.seasonName,
    required this.seasonEnd,
    required this.featuredModes,
    this.maintenanceMessage,
    required this.announcements,
  });

  Map<String, dynamic> toJson() => {
    'xpMultiplier': xpMultiplier,
    'seasonName': seasonName,
    'seasonEnd': seasonEnd.toIso8601String(),
    'featuredModes': featuredModes,
    'maintenanceMessage': maintenanceMessage,
    'announcements': announcements.map((a) => a.toJson()).toList(),
  };

  factory LiveConfig.fromJson(Map<String, dynamic> json) => LiveConfig(
    xpMultiplier: (json['xpMultiplier'] as num? ?? 1.0).toDouble(),
    seasonName: json['seasonName'] as String? ?? '',
    seasonEnd: DateTime.parse(
      json['seasonEnd'] as String? ?? DateTime.now().toIso8601String(),
    ),
    featuredModes: List<String>.from(json['featuredModes'] as List? ?? []),
    maintenanceMessage: json['maintenanceMessage'] as String?,
    announcements: (json['announcements'] as List? ?? [])
        .map((a) => Announcement.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}

/// Operations queued during offline periods.
enum OfflineTaskType { uploadProfile, uploadStats, uploadMatchSummary }

class OfflineTask {
  final String id;
  final OfflineTaskType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const OfflineTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  OfflineTask copyWith({int? retryCount}) {
    return OfflineTask(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory OfflineTask.fromJson(Map<String, dynamic> json) => OfflineTask(
    id: json['id'] as String,
    type: OfflineTaskType.values.firstWhere((t) => t.name == json['type']),
    payload: json['payload'] as Map<String, dynamic>,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );
}
