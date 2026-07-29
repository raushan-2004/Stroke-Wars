import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/home/presentation/home_page.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/profile/presentation/player_setup_page.dart';
import 'package:stroke_wars/features/profile/presentation/profile_edit_page.dart';
import 'package:stroke_wars/features/profile/presentation/profile_page.dart';
import 'package:stroke_wars/features/settings/presentation/settings_page.dart';
import 'package:stroke_wars/features/splash/presentation/splash_page.dart';

part 'app_router.g.dart';

/// Named route constants to avoid magic strings throughout the app.
abstract final class AppRoutes {
  /// The path for the initial splash / loading screen.
  static const String splash = '/';

  /// The path for the main home / hub screen.
  static const String home = '/home';

  /// The path for the player onboarding setup screen.
  static const String setup = '/setup';

  /// The path for the player profile screen.
  static const String profile = '/profile';

  /// The path for editing player cosmetics and preferences.
  static const String profileEdit = '/profile/edit';

  /// The path for the settings screen.
  static const String settings = '/settings';
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
          return const HomePage();
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
    ],
  );
}
