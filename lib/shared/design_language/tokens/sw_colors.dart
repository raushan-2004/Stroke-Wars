import 'package:flutter/material.dart';

/// Centralized color tokens for Stroke Wars Design Language (SWDL).
///
/// Follows a premium, dark-first competitive mobile game theme.
abstract final class SWColors {
  // --- Brand Colors ---

  /// Primary brand color (Vibrant Purple).
  static const Color primary = Color(0xFF6366F1);

  /// Secondary brand color (Neon Cyan / Electric Blue).
  static const Color secondary = Color(0xFF06B6D4);

  // --- Dark Theme Layered Surfaces ---

  /// Deepest background color.
  static const Color background = Color(0xFF0B0A0F);

  /// Default surface color for primary cards/modals.
  static const Color surface = Color(0xFF16141F);

  /// Overlay/container surface color for elevated elements.
  static const Color surfaceContainer = Color(0xFF221F30);

  /// Highlighted surface color.
  static const Color surfaceContainerHighest = Color(0xFF2D2940);

  /// Border and stroke divider color.
  static const Color border = Color(0xFF2A2738);

  /// Highlight/focused border color.
  static const Color borderActive = Color(0xFF4338CA);

  // --- Game Status Colors ---

  /// Matchmaking/Status: Online.
  static const Color online = Color(0xFF10B981);

  /// Matchmaking/Status: Offline / Disabled.
  static const Color offline = Color(0xFF6B7280);

  /// Connection Mode: LAN / Local Play.
  static const Color lan = Color(0xFF3B82F6);

  /// Connection Mode: Bluetooth.
  static const Color bluetooth = Color(0xFF8B5CF6);

  /// Game State: XP Gain / Progress.
  static const Color xp = Color(0xFFF59E0B);

  /// Game State: Victory / Gold Reward.
  static const Color victory = Color(0xFFFFD700);

  /// Game State: Leaderboard Rank 1.
  static const Color rankFirst = Color(0xFFFFD700);

  /// Game State: Leaderboard Rank 2.
  static const Color rankSecond = Color(0xFFC0C0C0);

  /// Game State: Leaderboard Rank 3.
  static const Color rankThird = Color(0xFFCD7F32);

  // --- Alert / Status Colors ---

  /// Status: Success.
  static const Color success = Color(0xFF10B981);

  /// Status: Danger / Error.
  static const Color danger = Color(0xFFEF4444);

  /// Status: Warning.
  static const Color warning = Color(0xFFF59E0B);

  /// Status: Info.
  static const Color info = Color(0xFF3B82F6);

  // --- Text & Foreground ---

  /// High-contrast primary text.
  static const Color textPrimary = Color(0xFFF9FAFB);

  /// Medium-contrast secondary text.
  static const Color textSecondary = Color(0xFF9CA3AF);

  /// Muted / disabled placeholder text.
  static const Color textMuted = Color(0xFF6B7280);

  /// Text color drawn on top of the primary color.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text color drawn on top of the secondary color.
  static const Color onSecondary = Color(0xFF0B0A0F);

  // --- Glassmorphic Shading ---

  /// Subtle glass overlay background.
  static const Color glassBackground = Color(0x1F1F1E2C);

  /// Subtle glass overlay boundary border.
  static const Color glassBorder = Color(0x1FCCCCCC);
}
