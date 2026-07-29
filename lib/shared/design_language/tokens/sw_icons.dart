import 'package:flutter/material.dart';

/// Centralized icon mappings for Stroke Wars Design Language (SWDL).
///
/// Prevents raw dependency on [Icons] inside screen features.
/// Allows swapping the underlying icon pack (e.g. FontAwesome, custom SVG)
/// by modifying only this file.
abstract final class SWIcons {
  /// App settings.
  static const IconData settings = Icons.settings_rounded;

  /// Player Profile.
  static const IconData profile = Icons.person_rounded;

  /// Game Mode: Online worldwide matchmaking.
  static const IconData modeOnline = Icons.public_rounded;

  /// Game Mode: LAN play.
  static const IconData modeLAN = Icons.router_rounded;

  /// Game Mode: Bluetooth pairing play.
  static const IconData modeBluetooth = Icons.bluetooth_rounded;

  /// Game Mode: Offline local play.
  static const IconData modeOffline = Icons.wifi_off_rounded;

  /// Navigation: Back arrow.
  static const IconData back = Icons.arrow_back_ios_new_rounded;

  /// Navigation: Close button.
  static const IconData close = Icons.close_rounded;

  /// Status: Success check.
  static const IconData check = Icons.check_circle_rounded;

  /// Status: Error alert.
  static const IconData error = Icons.error_outline_rounded;

  /// Status: General information.
  static const IconData info = Icons.info_outline_rounded;

  /// Drawing Tool: Brush thickness and color.
  static const IconData brush = Icons.brush_rounded;

  /// Drawing Tool: Eraser tool.
  static const IconData eraser = Icons.backspace_outlined;

  /// Drawing Tool: Color palette picker.
  static const IconData colorPicker = Icons.palette_rounded;

  /// Drawing Tool: Undo draw step.
  static const IconData undo = Icons.undo_rounded;

  /// Drawing Tool: Redo draw step.
  static const IconData redo = Icons.redo_rounded;

  /// Drawing Tool: Clear full canvas.
  static const IconData clear = Icons.delete_outline_rounded;

  /// Drawing Tool: Paint bucket fill.
  static const IconData fill = Icons.format_color_fill_rounded;

  /// Chat: Message bubble.
  static const IconData chat = Icons.chat_bubble_outline_rounded;

  /// Chat: Send message arrow.
  static const IconData send = Icons.send_rounded;

  /// Trophy award icon.
  static const IconData trophy = Icons.emoji_events_rounded;

  /// Leaderboard ranking display.
  static const IconData rank = Icons.leaderboard_rounded;

  /// Copy text key to clipboard.
  static const IconData copy = Icons.content_copy_rounded;

  /// Add / Join player.
  static const IconData add = Icons.add_rounded;

  /// Edit text fields.
  static const IconData edit = Icons.edit_rounded;

  /// Share links/room codes.
  static const IconData share = Icons.share_rounded;
}

/// Custom icon wrapper to enforce SWDL icon metrics and sizes.
class SWIcon extends StatelessWidget {
  /// Creates an [SWIcon] widget.
  const SWIcon(this.icon, {super.key, this.color, this.size});

  /// The mapped [IconData] to display.
  final IconData icon;

  /// Custom icon color (uses theme defaults if null).
  final Color? color;

  /// Custom icon size (uses responsive size tokens if null).
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: size ?? 24.0, // default size mapping
    );
  }
}
