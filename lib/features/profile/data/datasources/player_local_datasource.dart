import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/core/constants/app_constants.dart';
import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';

part 'player_local_datasource.g.dart';

/// Local data source interface for Hive player operations.
abstract interface class PlayerLocalDataSource {
  /// Reads the raw player JSON map from storage, returning null if empty.
  Map<String, dynamic>? getPlayerRaw();

  /// Writes the raw player JSON map to storage.
  Future<void> savePlayerRaw(Map<String, dynamic> raw);

  /// Clears player storage completely.
  Future<void> clearPlayer();
}

/// Concrete Hive implementation of [PlayerLocalDataSource].
class PlayerLocalDataSourceImpl implements PlayerLocalDataSource {
  /// Creates a [PlayerLocalDataSourceImpl].
  PlayerLocalDataSourceImpl({required StorageService storageService})
    : _storage = storageService;

  final StorageService _storage;

  @override
  Map<String, dynamic>? getPlayerRaw() {
    final value = _storage.get<dynamic>(AppConstants.playerKey);
    if (value == null) return null;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String) {
      try {
        return json.decode(value) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> savePlayerRaw(Map<String, dynamic> raw) async {
    await _storage.put<dynamic>(AppConstants.playerKey, json.encode(raw));
  }

  @override
  Future<void> clearPlayer() async {
    await _storage.delete(AppConstants.playerKey);
  }
}

/// Riverpod provider for the [PlayerLocalDataSource].
@riverpod
PlayerLocalDataSource playerLocalDataSource(PlayerLocalDataSourceRef ref) {
  final storage = ref.watch(storageServiceProvider);
  return PlayerLocalDataSourceImpl(storageService: storage);
}
