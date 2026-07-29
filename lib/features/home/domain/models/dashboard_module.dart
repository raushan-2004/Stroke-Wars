import 'package:flutter/material.dart';

/// The development or release status of a specific dashboard module.
enum FeatureState {
  /// Module is fully implemented and accessible.
  enabled,

  /// Module is planned for a future development stage.
  comingSoon,

  /// Module is locked behind progression/level constraints.
  locked,

  /// Module is in public beta / developer feedback phase.
  experimental,

  /// Module is currently disabled by system config.
  disabled,
}

/// Structured configuration model representing a Game Command Center module.
class DashboardModule {
  /// Creates a [DashboardModule] card definition.
  const DashboardModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.featureState,
    this.gradient,
    this.stage,
    this.badgeCount = 0,
  });

  /// Unique string identifier.
  final String id;

  /// Human-readable title.
  final String title;

  /// Informational subtitle.
  final String subtitle;

  /// Icon representing this action.
  final IconData icon;

  /// Destination GoRouter path.
  final String route;

  /// Active feature state control.
  final FeatureState featureState;

  /// Optional custom background gradient override.
  final Gradient? gradient;

  /// Target developmental stage label (e.g. "Coming in Stage 5").
  final String? stage;

  /// Dynamic badge notifications count.
  final int badgeCount;

  /// Returns whether this module can be tapped and navigated to.
  bool get isInteractive =>
      featureState == FeatureState.enabled ||
      featureState == FeatureState.experimental;
}
