import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';
import 'package:stroke_wars/features/home/domain/repositories/dashboard_registry.dart';
import 'package:stroke_wars/features/home/presentation/game_command_center_page.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/domain/models/player.dart';
import 'package:stroke_wars/features/profile/domain/models/player_cosmetics.dart';
import 'package:stroke_wars/features/profile/domain/models/player_settings.dart';
import 'package:stroke_wars/features/profile/domain/models/player_statistics.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class FakeStorageService implements StorageService {
  final Map<String, dynamic> _data = {};

  @override
  T? get<T>(String key) => _data[key] as T?;

  @override
  Future<void> put<T>(String key, T value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

void main() {
  group('Game Command Center (GCC) - Widget Tests', () {
    late FakeStorageService fakeStorage;

    setUp(() {
      fakeStorage = FakeStorageService();

      final player = Player(
        uuid: 'test-uuid-1234',
        displayName: 'Test Gamer',
        username: null,
        profilePicturePath: null,
        settings: PlayerSettings.initial().copyWith(
          themeMode: 'dark',
          accentColor: 'purple',
        ),
        cosmetics: PlayerCosmetics.initial().copyWith(
          avatarId: 'robot',
          theme: 'dark',
          accentColor: 'purple',
        ),
        statistics: PlayerStatistics.initial(),
        achievementsUnlocked: const [],
        createdAt: DateTime.now(),
        lastPlayed: DateTime.now(),
        appVersion: '1.0.0',
      );

      // Seed a default player profile in storage so playerServiceProvider initializes synchronously.
      fakeStorage.put('player_data', json.encode(player.toJson()));
    });

    Widget buildTestApp(Widget child) {
      return ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(fakeStorage)],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, c) => MaterialApp(home: child),
        ),
      );
    }

    testWidgets('DashboardRegistry rendering shows all modules', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Render the GameCommandCenterPage
      await tester.pumpWidget(buildTestApp(const GameCommandCenterPage()));
      await tester.pumpAndSettle();

      // Verify the player display name in header
      expect(find.text('Test Gamer'), findsOneWidget);

      // Verify primary gaming modules render (e.g. Quick Play, Create Room, Join Room)
      expect(find.text('Quick Play'), findsOneWidget);
      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Join Room'), findsOneWidget);
      expect(find.text('LAN Play'), findsOneWidget);
      expect(find.text('Bluetooth Play'), findsOneWidget);

      // Verify secondary configuration modules render (e.g. Settings, Locker, Achievements)
      expect(find.text('Settings'), findsOneWidget);

      // Flush microtasks and complete any scheduled Riverpod auto-dispose timers.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    });

    testWidgets(
      'FeatureState rendering shows stage badges for upcoming features',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        addTearDown(tester.view.resetPhysicalSize);

        final registry = DashboardRegistry();
        final bluetoothModule = registry.getPrimaryModules().firstWhere(
          (m) => m.id == 'bluetooth_play',
        );

        await tester.pumpWidget(
          buildTestApp(
            Scaffold(body: SWDashboardCard(module: bluetoothModule)),
          ),
        );

        await tester.pumpAndSettle();

        // Verify stage badge is present (e.g. "Stage 5" or similar)
        expect(find.text('Stage 5'), findsOneWidget);

        // Flush microtasks and complete any scheduled Riverpod auto-dispose timers.
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
      },
    );

    testWidgets('SWPlayerSummary renders name, badge, and progress ring', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1920);
      addTearDown(tester.view.resetPhysicalSize);

      // Create a test player model manually
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(fakeStorage)],
      );
      final playerService = container.read(playerServiceProvider.notifier);
      await playerService.createPlayer(
        displayName: 'Hero Sketcher',
        avatarId: 'wizard',
        themeMode: 'system',
        accentColor: 'cyan',
      );
      final player = container.read(playerServiceProvider)!;
      container.dispose(); // clean up container synchronously

      await tester.pumpWidget(
        buildTestApp(Scaffold(body: SWPlayerSummary(player: player))),
      );

      await tester.pumpAndSettle();

      // Verify summary elements
      expect(find.text('Hero Sketcher'), findsOneWidget);
      expect(find.text('ROOKIE'), findsOneWidget);
      expect(find.byType(SWAvatarRing), findsOneWidget);

      // Flush microtasks and complete any scheduled Riverpod auto-dispose timers.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    });
  });
}
