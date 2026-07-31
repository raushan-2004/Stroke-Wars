import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';
import 'package:stroke_wars/features/competitive/application/progression_service.dart';
import 'package:stroke_wars/features/competitive/application/ranked_service.dart';
import 'package:stroke_wars/features/competitive/application/mission_engine.dart';
import 'package:stroke_wars/features/competitive/application/economy_service.dart';
import 'package:stroke_wars/features/competitive/application/social_service.dart';
import 'package:stroke_wars/features/competitive/application/notification_center.dart';

void main() {
  group('Competitive Ecosystem & Social Platform (Stage 11) — Integration Tests', () {
    late ProgressionEngine progressionEngine;
    late RankedService rankedService;
    late MissionEngine missionEngine;
    late EconomyService economyService;
    late SocialGraphService socialGraphService;
    late NotificationCenter notificationCenter;

    setUp(() {
      progressionEngine = ProgressionEngine();
      rankedService = RankedService();
      missionEngine = MissionEngine();
      economyService = EconomyService();
      socialGraphService = SocialGraphService();
      notificationCenter = NotificationCenter();
    });

    test(
      'ProgressionEngine level calculations, Prestige milestones, and Title unlocks',
      () {
        var prog = const PlayerProgression(
          xp: 0,
          level: 1,
          seasonXp: 0,
          rank: 'Bronze I',
          prestige: 0,
          badges: [],
          titles: [],
          unlockHistory: [],
        );

        // Level 1 to Level 2 requires 1000 XP
        prog = progressionEngine.addXp(prog, 1000);
        expect(prog.level, equals(2));
        expect(prog.xp, equals(0));

        // Level 2 to Level 3 requires 2000 XP
        prog = progressionEngine.addXp(prog, 2000);
        expect(prog.level, equals(3));

        // Large XP gain to unlock level 10 title "Scribbler"
        prog = progressionEngine.addXp(prog, 50000);
        expect(prog.level, greaterThanOrEqualTo(10));
        expect(prog.titles, contains('Scribbler'));

        // Reach Level 50+ to trigger prestige reset
        prog = progressionEngine.addXp(prog, 1500000);
        expect(prog.prestige, greaterThan(0));
        expect(prog.level, lessThanOrEqualTo(50));
        expect(prog.badges.any((b) => b.contains('prestige_')), isTrue);
      },
    );

    test('RankedService MMR Elo computations, tiers, and decays', () {
      // Elo formula verification
      final winChange = rankedService.calculateMmrChange(1500, 1500, true);
      expect(
        winChange,
        equals(16),
      ); // Expected Elo change with K=32 against equal opponent

      final lossChange = rankedService.calculateMmrChange(1500, 1500, false);
      expect(lossChange, equals(-16));

      // Placement matches status
      expect(rankedService.evaluatePlacement(3, 2), contains('Unranked'));
      expect(rankedService.evaluatePlacement(5, 4), equals('Gold I'));

      // Inactivity MMR decay above Gold
      expect(
        rankedService.applyDecay(1000, 15),
        equals(1000),
      ); // Bronze: no decay
      expect(
        rankedService.applyDecay(1500, 15),
        equals(1380),
      ); // Gold: decays over 7 days

      // Season Reset formula (soft reset)
      expect(
        rankedService.applySeasonReset(1800),
        equals(1500),
      ); // Reset towards median 1200
    });

    test('MissionEngine evaluations, rewards, and claim resets', () {
      var active = missionEngine.generateDailyMissions();
      expect(active, hasLength(3));

      // Update draw progress
      active = missionEngine.processProgress(
        activeMissions: active,
        actionType: 'draw',
        increment: 2,
      );
      expect(active.first.currentValue, equals(2));
      expect(active.first.isCompleted, isFalse);

      // Complete mission
      active = missionEngine.processProgress(
        activeMissions: active,
        actionType: 'draw',
        increment: 1,
      );
      expect(active.first.currentValue, equals(3));
      expect(active.first.isCompleted, isTrue);

      // Fresh generation to verify resets
      final fresh = missionEngine.generateDailyMissions();
      expect(fresh.first.currentValue, equals(0));
    });

    test(
      'EconomyService inventory locking, currency transactions, and double purchases',
      () {
        final item = const ShopItem(
          id: 'brush_neon',
          title: 'Neon Brush Skin',
          category: 'brush',
          price: 100,
          currency: 'Coins',
          isAnimated: true,
        );

        // Default coins balance is 500
        expect(economyService.coins, equals(500));
        expect(economyService.ownsItem(item.id), isFalse);

        final success = economyService.purchaseItem(item);
        expect(success, isTrue);
        expect(economyService.coins, equals(400));
        expect(economyService.ownsItem(item.id), isTrue);

        // Duplicate purchase does not deduct balance again
        final doublePurchase = economyService.purchaseItem(item);
        expect(doublePurchase, isTrue);
        expect(economyService.coins, equals(400));
      },
    );

    test(
      'SocialGraphService friend lifecycles, presence updates, and party invitations',
      () {
        expect(socialGraphService.friends, hasLength(3));

        // Update Presence
        socialGraphService.updatePresence('f-1', 'ingame');
        expect(
          socialGraphService.friends
              .firstWhere((f) => f.userId == 'f-1')
              .presence,
          equals('ingame'),
        );

        // Accept friend request
        expect(socialGraphService.friendRequests, hasLength(1));
        socialGraphService.acceptFriendRequest('r-1');
        expect(socialGraphService.friendRequests, isEmpty);
        expect(
          socialGraphService.friends.any((f) => f.userId == 'r-1'),
          isTrue,
        );

        // Party formation
        socialGraphService.createParty('host-player');
        expect(socialGraphService.currentParty, isNotNull);
        expect(
          socialGraphService.currentParty!.members,
          contains('host-player'),
        );
      },
    );

    test('NotificationCenter chronological buffering order', () {
      notificationCenter.postNotification(
        title: 'Alert 1',
        body: 'Body 1',
        type: 'news',
      );
      notificationCenter.postNotification(
        title: 'Alert 2',
        body: 'Body 2',
        type: 'news',
      );

      final list = notificationCenter.notifications;
      expect(list, hasLength(2));
      // First item in the list must be the newest (Alert 2)
      expect(list.first.title, equals('Alert 2'));
    });
  });
}
