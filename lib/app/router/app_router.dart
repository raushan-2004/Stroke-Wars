import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/home/presentation/home_page.dart';
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

  /// The path for the player profile screen.
  static const String profile = '/profile';

  /// The path for the settings screen.
  static const String settings = '/settings';
}

/// Provides the central [GoRouter] instance configured with app routes.
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
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
        path: AppRoutes.profile,
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfilePage();
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
