import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/home/domain/models/dashboard_module.dart';

part 'dashboard_registry.g.dart';

/// Single source of truth registry for all Game Command Center modules.
class DashboardRegistry {
  /// Loads all primary gaming modules.
  List<DashboardModule> getPrimaryModules() {
    return const [
      DashboardModule(
        id: 'quick_play',
        title: 'Quick Play',
        subtitle: 'Instant matchmaking. Jump into a live game.',
        icon: Icons.play_arrow_rounded,
        route: '/play',
        featureState: FeatureState.enabled,
      ),
      DashboardModule(
        id: 'create_room',
        title: 'Create Room',
        subtitle: 'Host a private game room and invite friends.',
        icon: Icons.add_box_rounded,
        route: '/create-room',
        featureState: FeatureState.enabled,
      ),
      DashboardModule(
        id: 'join_room',
        title: 'Join Room',
        subtitle: 'Enter a custom lobby code to join a game.',
        icon: Icons.group_add_rounded,
        route: '/join-room',
        featureState: FeatureState.enabled,
      ),
      DashboardModule(
        id: 'lan_play',
        title: 'LAN Play',
        subtitle: 'Play over local Wi-Fi or mobile hotspots.',
        icon: Icons.wifi_rounded,
        route: '/lan',
        featureState: FeatureState.comingSoon,
        stage: 'Stage 6',
      ),
      DashboardModule(
        id: 'bluetooth_play',
        title: 'Bluetooth Play',
        subtitle: 'Connect peer-to-peer using local devices.',
        icon: Icons.bluetooth_rounded,
        route: '/bluetooth',
        featureState: FeatureState.comingSoon,
        stage: 'Stage 5',
      ),
      DashboardModule(
        id: 'practice_mode',
        title: 'Practice Mode',
        subtitle: 'Refine your sketching speed and precision.',
        icon: Icons.brush_rounded,
        route: '/practice',
        featureState: FeatureState.enabled,
      ),
    ];
  }

  /// Loads all secondary profile / administrative modules.
  List<DashboardModule> getSecondaryModules() {
    return const [
      DashboardModule(
        id: 'profile',
        title: 'Profile Hub',
        subtitle: 'View rank details and summary.',
        icon: Icons.account_circle_rounded,
        route: '/profile',
        featureState: FeatureState.enabled,
      ),
      DashboardModule(
        id: 'statistics',
        title: 'Statistics',
        subtitle: 'Review match metrics and drawing times.',
        icon: Icons.bar_chart_rounded,
        route: '/statistics',
        featureState: FeatureState.enabled,
      ),
      DashboardModule(
        id: 'achievements',
        title: 'Achievements',
        subtitle: 'Showcase your unlocked accomplishments.',
        icon: Icons.emoji_events_rounded,
        route: '/achievements',
        featureState: FeatureState.enabled,
      ),
      DashboardModule(
        id: 'customization',
        title: 'Locker',
        subtitle: 'Customize brush tips and avatar borders.',
        icon: Icons.palette_rounded,
        route: '/customization',
        featureState: FeatureState.comingSoon,
        stage: 'Stage 4',
      ),
      DashboardModule(
        id: 'settings',
        title: 'Settings',
        subtitle: 'Configure audio, haptic, and visual setups.',
        icon: Icons.settings_rounded,
        route: '/settings',
        featureState: FeatureState.enabled,
      ),
      DashboardModule(
        id: 'help',
        title: 'Rules & Help',
        subtitle: 'Learn how to play and gain points.',
        icon: Icons.help_outline_rounded,
        route: '/help',
        featureState: FeatureState.comingSoon,
        stage: 'Stage 3+',
      ),
      DashboardModule(
        id: 'about',
        title: 'About',
        subtitle: 'Stroke Wars version details.',
        icon: Icons.info_outline_rounded,
        route: '/about',
        featureState: FeatureState.comingSoon,
        stage: 'Stage 3+',
      ),
    ];
  }
}

/// Riverpod provider to access the [DashboardRegistry].
@riverpod
DashboardRegistry dashboardRegistry(DashboardRegistryRef ref) {
  return DashboardRegistry();
}
