import 'package:stroke_wars/features/profile/domain/models/player.dart';

/// Interface defining storage and retrieval of player aggregate.
abstract interface class PlayerRepository {
  /// Fetches the current active player from local database.
  Player? getPlayer();

  /// Persists player aggregate properties locally.
  Future<void> savePlayer(Player player);

  /// Removes player settings and profiles.
  Future<void> clearPlayer();
}
