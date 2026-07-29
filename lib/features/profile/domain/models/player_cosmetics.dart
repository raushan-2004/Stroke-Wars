import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_cosmetics.freezed.dart';
part 'player_cosmetics.g.dart';

/// Player cosmetics preferences including avatars, frames, badges, colors, and brush.
@freezed
class PlayerCosmetics with _$PlayerCosmetics {
  /// Creates a [PlayerCosmetics].
  const factory PlayerCosmetics({
    required String avatarId,
    required String avatarFrame,
    required String badge,
    required String theme,
    required String accentColor,
    required String favoriteBrush,
    required String favoriteColor,
  }) = _PlayerCosmetics;

  /// Creates a [PlayerCosmetics] from JSON map.
  factory PlayerCosmetics.fromJson(Map<String, dynamic> json) =>
      _$PlayerCosmeticsFromJson(json);

  /// Default starting cosmetics.
  factory PlayerCosmetics.initial() => const PlayerCosmetics(
    avatarId: 'robot',
    avatarFrame: 'none',
    badge: 'Rookie',
    theme: 'dark',
    accentColor: 'purple',
    favoriteBrush: 'paintbrush',
    favoriteColor: '#8B5CF6', // Purple
  );
}
