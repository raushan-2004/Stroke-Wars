import 'package:flutter/material.dart';

/// The visual style type of a player avatar.
enum AvatarType {
  /// Default built-in vector representation.
  builtIn,

  /// Custom photo uploaded from gallery or camera.
  customPhoto,

  /// Exclusive unlockable premium style.
  premium,

  /// Limited time seasonal content style.
  seasonal,
}

/// Metadata definition for a built-in avatar configuration.
class BuiltInAvatarDef {
  /// Creates a [BuiltInAvatarDef].
  const BuiltInAvatarDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  /// The unique string identifier.
  final String id;

  /// The human-readable display name.
  final String name;

  /// Vector icon to render.
  final IconData icon;

  /// Dynamic glow/accent color.
  final Color color;
}

/// Definition for a cosmetic avatar frame border.
class AvatarFrameDef {
  /// Creates an [AvatarFrameDef].
  const AvatarFrameDef({
    required this.id,
    required this.name,
    required this.glowColor,
    required this.borderWidth,
    this.dashArray,
  });

  /// The unique string identifier.
  final String id;

  /// The human-readable display name.
  final String name;

  /// The color of the frame glow.
  final Color glowColor;

  /// Border line thickness.
  final double borderWidth;

  /// Optional dash pattern (tech styles).
  final List<double>? dashArray;
}

/// Central catalog for all avatars, cosmetics, and frames in Stroke Wars.
abstract final class AvatarFramework {
  /// Supported built-in avatars list.
  static const List<BuiltInAvatarDef> avatars = [
    BuiltInAvatarDef(
      id: 'robot',
      name: 'Android Bot',
      icon: Icons.smart_toy_rounded,
      color: Colors.cyan,
    ),
    BuiltInAvatarDef(
      id: 'wizard',
      name: 'Mystic Wizard',
      icon: Icons.auto_awesome_rounded,
      color: Colors.purple,
    ),
    BuiltInAvatarDef(
      id: 'pirate',
      name: 'Sea Pirate',
      icon: Icons.anchor_rounded,
      color: Colors.red,
    ),
    BuiltInAvatarDef(
      id: 'astronaut',
      name: 'Star Astronaut',
      icon: Icons.rocket_launch_rounded,
      color: Colors.indigo,
    ),
    BuiltInAvatarDef(
      id: 'samurai',
      name: 'Ronin Samurai',
      icon: Icons.shield_rounded,
      color: Colors.orange,
    ),
    BuiltInAvatarDef(
      id: 'fox',
      name: 'Swift Fox',
      icon: Icons.pets_rounded,
      color: Colors.amber,
    ),
    BuiltInAvatarDef(
      id: 'alien',
      name: 'Cosmic Alien',
      icon: Icons.face_unlock_rounded,
      color: Colors.green,
    ),
    BuiltInAvatarDef(
      id: 'knight',
      name: 'Iron Knight',
      icon: Icons.security_rounded,
      color: Colors.blueGrey,
    ),
    BuiltInAvatarDef(
      id: 'detective',
      name: 'Spy Detective',
      icon: Icons.search_rounded,
      color: Colors.deepPurple,
    ),
  ];

  /// Supported avatar frames list.
  static const List<AvatarFrameDef> frames = [
    AvatarFrameDef(
      id: 'none',
      name: 'No Frame',
      glowColor: Colors.transparent,
      borderWidth: 0,
    ),
    AvatarFrameDef(
      id: 'neon_glow',
      name: 'Neon Active',
      glowColor: Color(0xFF8B5CF6), // Neon Purple
      borderWidth: 2,
    ),
    AvatarFrameDef(
      id: 'golden_crest',
      name: 'Golden Champion',
      glowColor: Color(0xFFFBBF24), // Gold
      borderWidth: 3,
    ),
    AvatarFrameDef(
      id: 'cyber_grid',
      name: 'Cyberpunk Grid',
      glowColor: Color(0xFF06B6D4), // Cyan
      borderWidth: 2.5,
    ),
  ];

  /// Finds an avatar definition by ID, returning a default robot if not found.
  static BuiltInAvatarDef findAvatar(String id) {
    return avatars.firstWhere((a) => a.id == id, orElse: () => avatars.first);
  }

  /// Finds a frame definition by ID, returning 'none' if not found.
  static AvatarFrameDef findFrame(String id) {
    return frames.firstWhere((f) => f.id == id, orElse: () => frames.first);
  }
}
