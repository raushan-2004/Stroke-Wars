import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:stroke_wars/features/profile/domain/models/player_cosmetics.dart';
import 'package:stroke_wars/features/profile/domain/models/player_settings.dart';
import 'package:stroke_wars/features/profile/domain/models/player_statistics.dart';

part 'player.freezed.dart';
part 'player.g.dart';

/// The root Player aggregate model representing the user identity.
@freezed
class Player with _$Player {
  /// Creates a [Player].
  const factory Player({
    required String uuid,
    required String displayName,
    required String? username,
    required String? profilePicturePath,
    required PlayerSettings settings,
    required PlayerCosmetics cosmetics,
    required PlayerStatistics statistics,
    required List<String> achievementsUnlocked,
    required DateTime createdAt,
    required DateTime lastPlayed,
    required String appVersion,
  }) = _Player;

  /// Creates a [Player] from JSON map.
  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
