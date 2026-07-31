import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/practice/presentation/practice_page.dart';
import 'package:stroke_wars/features/lan/presentation/lan_session_page.dart';
import 'package:stroke_wars/features/online/presentation/online_session_page.dart';
import 'package:stroke_wars/features/home/domain/repositories/dashboard_registry.dart';
import 'package:stroke_wars/features/home/presentation/game_command_center_page.dart';
import 'package:stroke_wars/features/home/presentation/placeholder_page.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/presentation/player_setup_page.dart';
import 'package:stroke_wars/features/profile/presentation/profile_edit_page.dart';
import 'package:stroke_wars/features/profile/presentation/profile_page.dart';
import 'package:stroke_wars/features/settings/presentation/settings_page.dart';
import 'package:stroke_wars/features/showcase/presentation/showcase_page.dart';
import 'package:stroke_wars/features/splash/presentation/splash_page.dart';
import 'package:stroke_wars/features/replay/presentation/match_history_page.dart';
import 'package:stroke_wars/features/replay/presentation/replay_page.dart';
import 'package:stroke_wars/features/competitive/presentation/social_hub_page.dart';
import 'package:stroke_wars/features/competitive/presentation/missions_page.dart';
import 'package:stroke_wars/features/competitive/presentation/shop_page.dart';
import 'package:stroke_wars/features/competitive/presentation/leaderboards_page.dart';

part 'app_router.g.dart';

/// Named route constants to avoid magic strings throughout the app.
abstract final class AppRoutes {
  /// The path for the initial splash / loading screen.
  static const String splash = '/';

  /// The path for the main home / hub screen (Game Command Center).
  static const String home = '/home';

  /// The path for the player onboarding setup screen.
  static const String setup = '/setup';

  /// The path for the player profile screen.
  static const String profile = '/profile';

  /// The path for editing player cosmetics and preferences.
  static const String profileEdit = '/profile/edit';

  /// The path for the settings screen.
  static const String settings = '/settings';

  /// The path for the developer component showcase.
  static const String showcase = '/showcase';

  /// The path for replays and match history.
  static const String replays = '/replays';
}

/// Provides the central [GoRouter] instance configured with app routes and PIS redirects.
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final playerService = ref.read(playerServiceProvider.notifier);
      final hasPlayer = playerService.hasPlayer();

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isSetup = state.matchedLocation == AppRoutes.setup;

      if (isSplash) return null;

      // Force setup onboarding if no local profile exists
      if (!hasPlayer && !isSetup) {
        return AppRoutes.setup;
      }

      // Prevent accessing setup onboarding once completed
      if (hasPlayer && isSetup) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) {
          return const GameCommandCenterPage();
        },
      ),
      GoRoute(
        path: AppRoutes.showcase,
        name: 'showcase',
        builder: (BuildContext context, GoRouterState state) {
          return const ShowcasePage();
        },
      ),
      GoRoute(
        path: AppRoutes.setup,
        name: 'setup',
        builder: (BuildContext context, GoRouterState state) {
          return const PlayerSetupPage();
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfilePage();
        },
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile_edit',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileEditPage();
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsPage();
        },
      ),

      // GCC Placeholder routes dynamically resolved from registry
      GoRoute(
        path: '/play',
        name: 'play',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getPrimaryModules()
              .firstWhere((m) => m.id == 'quick_play');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/create-room',
        name: 'create_room',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getPrimaryModules()
              .firstWhere((m) => m.id == 'create_room');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/join-room',
        name: 'join_room',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getPrimaryModules()
              .firstWhere((m) => m.id == 'join_room');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/lan',
        name: 'lan',
        builder: (BuildContext context, GoRouterState state) {
          return const LANSessionPage();
        },
      ),
      GoRoute(
        path: '/online',
        name: 'online',
        builder: (BuildContext context, GoRouterState state) {
          return const OnlineSessionPage();
        },
      ),
      GoRoute(
        path: '/bluetooth',
        name: 'bluetooth',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getPrimaryModules()
              .firstWhere((m) => m.id == 'bluetooth_play');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/practice',
        name: 'practice',
        builder: (BuildContext context, GoRouterState state) {
          return const PracticePage();
        },
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getSecondaryModules()
              .firstWhere((m) => m.id == 'statistics');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getSecondaryModules()
              .firstWhere((m) => m.id == 'achievements');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/customization',
        name: 'customization',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getSecondaryModules()
              .firstWhere((m) => m.id == 'customization');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getSecondaryModules()
              .firstWhere((m) => m.id == 'help');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (BuildContext context, GoRouterState state) {
          final module = ref
              .read(dashboardRegistryProvider)
              .getSecondaryModules()
              .firstWhere((m) => m.id == 'about');
          return SWPlaceholderPage(module: module);
        },
      ),
      GoRoute(
        path: '/replays',
        name: 'replays',
        builder: (BuildContext context, GoRouterState state) {
          return const MatchHistoryPage();
        },
        routes: [
          GoRoute(
            path: ':replayId',
            name: 'replay_view',
            builder: (BuildContext context, GoRouterState state) {
              final replayId = state.pathParameters['replayId']!;
              return ReplayPage(replayId: replayId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/social',
        name: 'social',
        builder: (BuildContext context, GoRouterState state) {
          return const SocialHubPage();
        },
      ),
      GoRoute(
        path: '/missions',
        name: 'missions',
        builder: (BuildContext context, GoRouterState state) {
          return const MissionsPage();
        },
      ),
      GoRoute(
        path: '/shop',
        name: 'shop',
        builder: (BuildContext context, GoRouterState state) {
          return const ShopPage();
        },
      ),
      GoRoute(
        path: '/leaderboards',
        name: 'leaderboards',
        builder: (BuildContext context, GoRouterState state) {
          return const LeaderboardsPage();
        },
      ),
    ],
  );
}
