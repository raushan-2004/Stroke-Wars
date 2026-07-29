import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/home/domain/models/dashboard_module.dart';

part 'navigation_service.g.dart';

/// Service class abstracting GoRouter navigation paths from the UI.
class NavigationService {
  /// Opens the Profile Hub page.
  void openProfile(BuildContext context) => context.push('/profile');

  /// Opens the Settings page.
  void openSettings(BuildContext context) => context.push('/settings');

  /// Opens the LAN play page.
  void openLan(BuildContext context) => context.push('/lan');

  /// Opens the Bluetooth play page.
  void openBluetooth(BuildContext context) => context.push('/bluetooth');

  /// Opens the Statistics summary page.
  void openStatistics(BuildContext context) => context.push('/statistics');

  /// Opens the Achievements list page.
  void openAchievements(BuildContext context) => context.push('/achievements');

  /// Opens the Locker customization page.
  void openCustomization(BuildContext context) =>
      context.push('/customization');

  /// Opens the Quick Play matchmaking page.
  void openPlay(BuildContext context) => context.push('/play');

  /// Opens the Create Room page.
  void openCreateRoom(BuildContext context) => context.push('/create-room');

  /// Opens the Join Room page.
  void openJoinRoom(BuildContext context) => context.push('/join-room');

  /// Opens the developer showcase sandbox.
  void openShowcase(BuildContext context) => context.push('/showcase');

  /// Dynamically routes to the page matching the specified module.
  void navigateToModule(BuildContext context, DashboardModule module) {
    context.push(module.route);
  }
}

/// Riverpod provider for the [NavigationService].
@riverpod
NavigationService navigationService(NavigationServiceRef ref) {
  return NavigationService();
}
