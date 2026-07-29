import 'package:flutter/material.dart';

/// Centralized shadows and glowing backdrops for Stroke Wars Design Language
/// (SWDL).
abstract final class SWShadows {
  /// Soft ambient shadow for lists or low-elevation cards.
  static List<BoxShadow> get soft => const [
    BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  /// Medium shadow for primary dashboard widgets.
  static List<BoxShadow> get medium => const [
    BoxShadow(color: Color(0x3D000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Highly elevated floating shadow for sheets, dialogs, and popups.
  static List<BoxShadow> get floating => const [
    BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 12)),
  ];

  /// Neon brand glow shadow (Vibrant Purple).
  static List<BoxShadow> get glowPurple => const [
    BoxShadow(color: Color(0x336366F1), blurRadius: 20, spreadRadius: 2),
  ];

  /// Neon status glow shadow (Amber Warning / XP).
  static List<BoxShadow> get glowOrange => const [
    BoxShadow(color: Color(0x33F59E0B), blurRadius: 20, spreadRadius: 2),
  ];

  /// Victory / Premium gold glow shadow.
  static List<BoxShadow> get glowGold => const [
    BoxShadow(color: Color(0x33FFD700), blurRadius: 20, spreadRadius: 2),
  ];
}
