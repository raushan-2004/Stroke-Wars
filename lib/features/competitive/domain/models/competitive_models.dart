/// PlayerProgression tracks long term and seasonal progress markers.
class PlayerProgression {
  final int xp;
  final int level;
  final int seasonXp;
  final String rank;
  final int prestige;
  final List<String> badges;
  final List<String> titles;
  final List<String> unlockHistory;

  const PlayerProgression({
    required this.xp,
    required this.level,
    required this.seasonXp,
    required this.rank,
    required this.prestige,
    required this.badges,
    required this.titles,
    required this.unlockHistory,
  });

  PlayerProgression copyWith({
    int? xp,
    int? level,
    int? seasonXp,
    String? rank,
    int? prestige,
    List<String>? badges,
    List<String>? titles,
    List<String>? unlockHistory,
  }) {
    return PlayerProgression(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      seasonXp: seasonXp ?? this.seasonXp,
      rank: rank ?? this.rank,
      prestige: prestige ?? this.prestige,
      badges: badges ?? this.badges,
      titles: titles ?? this.titles,
      unlockHistory: unlockHistory ?? this.unlockHistory,
    );
  }
}

/// Mapped profile data for a specific season.
class SeasonProgress {
  final String seasonId;
  final int seasonXp;
  final int currentTier;
  final List<String> rewardsClaimed;
  final List<String> challengesCompleted;

  const SeasonProgress({
    required this.seasonId,
    required this.seasonXp,
    required this.currentTier,
    required this.rewardsClaimed,
    required this.challengesCompleted,
  });

  SeasonProgress copyWith({
    String? seasonId,
    int? seasonXp,
    int? currentTier,
    List<String>? rewardsClaimed,
    List<String>? challengesCompleted,
  }) {
    return SeasonProgress(
      seasonId: seasonId ?? this.seasonId,
      seasonXp: seasonXp ?? this.seasonXp,
      currentTier: currentTier ?? this.currentTier,
      rewardsClaimed: rewardsClaimed ?? this.rewardsClaimed,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
    );
  }
}

/// Configuration structure for a competitive season.
class Season {
  final String seasonId;
  final DateTime startDate;
  final DateTime endDate;
  final Map<int, String> rewards;
  final List<String> featuredModes;
  final String theme;
  final double xpMultiplier;

  const Season({
    required this.seasonId,
    required this.startDate,
    required this.endDate,
    required this.rewards,
    required this.featuredModes,
    required this.theme,
    required this.xpMultiplier,
  });
}

/// Mission tracking structures.
class DailyMission {
  final String id;
  final String title;
  final int targetValue;
  final int currentValue;
  final int rewardXp;
  final int rewardCurrency;
  final bool isCompleted;
  final bool isClaimed;

  const DailyMission({
    required this.id,
    required this.title,
    required this.targetValue,
    required this.currentValue,
    required this.rewardXp,
    required this.rewardCurrency,
    required this.isCompleted,
    required this.isClaimed,
  });

  DailyMission copyWith({
    int? currentValue,
    bool? isCompleted,
    bool? isClaimed,
  }) {
    return DailyMission(
      id: id,
      title: title,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      rewardXp: rewardXp,
      rewardCurrency: rewardCurrency,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

/// Store catalog offerings.
class ShopItem {
  final String id;
  final String title;
  final String category; // 'frame', 'brush', 'theme', 'badge', 'victory'
  final int price;
  final String currency;
  final bool isAnimated;

  const ShopItem({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.currency,
    required this.isAnimated,
  });
}

/// Social network profiles.
class Friend {
  final String userId;
  final String displayName;
  final String presence; // 'online', 'offline', 'ingame'

  const Friend({
    required this.userId,
    required this.displayName,
    required this.presence,
  });

  Friend copyWith({String? presence}) {
    return Friend(
      userId: userId,
      displayName: displayName,
      presence: presence ?? this.presence,
    );
  }
}

class FriendRequest {
  final String fromUserId;
  final String fromDisplayName;

  const FriendRequest({
    required this.fromUserId,
    required this.fromDisplayName,
  });
}

class Party {
  final String partyId;
  final String hostId;
  final List<String> members;

  const Party({
    required this.partyId,
    required this.hostId,
    required this.members,
  });
}

class Invite {
  final String partyId;
  final String senderName;

  const Invite({required this.partyId, required this.senderName});
}

/// Competitive announcement structures.
class SWNotification {
  final String id;
  final String title;
  final String body;
  final String
  type; // 'friend_request', 'mission_reward', 'season_reward', 'shop_unlock'
  final DateTime timestamp;

  const SWNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
  });
}
