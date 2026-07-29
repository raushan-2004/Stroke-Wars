import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/features/profile/data/datasources/player_local_datasource.dart';
import 'package:stroke_wars/features/profile/domain/models/player.dart';
import 'package:stroke_wars/features/profile/domain/repositories/player_repository.dart';

part 'player_repository_impl.g.dart';

/// Concrete implementor of [PlayerRepository] translating JSON streams.
class PlayerRepositoryImpl implements PlayerRepository {
  /// Creates a [PlayerRepositoryImpl].
  PlayerRepositoryImpl({required PlayerLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final PlayerLocalDataSource _localDataSource;

  @override
  Player? getPlayer() {
    final raw = _localDataSource.getPlayerRaw();
    if (raw == null) return null;
    try {
      return Player.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePlayer(Player player) async {
    await _localDataSource.savePlayerRaw(player.toJson());
  }

  @override
  Future<void> clearPlayer() async {
    await _localDataSource.clearPlayer();
  }
}

/// Riverpod provider for the [PlayerRepository].
@riverpod
PlayerRepository playerRepository(PlayerRepositoryRef ref) {
  final dataSource = ref.watch(playerLocalDataSourceProvider);
  return PlayerRepositoryImpl(localDataSource: dataSource);
}
