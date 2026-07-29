import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/core/constants/app_constants.dart';
import 'package:stroke_wars/core/exceptions/app_exception.dart';
import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';

part 'hive_storage_service.g.dart';

/// Hive-backed implementation of [StorageService].
///
/// Operates on the pre-opened [AppConstants.preferencesBoxName] box.
/// All operations are synchronous reads with async writes.
final class HiveStorageService implements StorageService {
  /// Creates a [HiveStorageService].
  HiveStorageService() : _box = Hive.box(AppConstants.preferencesBoxName);

  final Box<dynamic> _box;

  /// Opens all Hive boxes required at startup.
  /// Must be called before [HiveStorageService] is instantiated.
  static Future<void> openRequiredBoxes() async {
    await Hive.openBox<dynamic>(AppConstants.preferencesBoxName);
    await Hive.openBox<dynamic>(AppConstants.cacheBoxName);
  }

  @override
  T? get<T>(String key) {
    try {
      final value = _box.get(key);
      if (value == null) return null;
      if (value is T) return value;
      AppLogger.instance.warning(
        'Storage type mismatch for key "$key": '
        'expected $T, got ${value.runtimeType}',
      );
      return null;
    } on Object catch (e, stack) {
      AppLogger.instance.error(
        'Failed to read key "$key" from storage',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<void> put<T>(String key, T value) async {
    try {
      await _box.put(key, value);
    } on Object catch (e, stack) {
      AppLogger.instance.error(
        'Failed to write key "$key" to storage',
        error: e,
        stackTrace: stack,
      );
      throw StorageException(
        message: 'Failed to persist value for key: $key',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _box.delete(key);
    } on Object catch (e, stack) {
      AppLogger.instance.error(
        'Failed to delete key "$key" from storage',
        error: e,
        stackTrace: stack,
      );
      throw StorageException(
        message: 'Failed to delete key: $key',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  bool containsKey(String key) => _box.containsKey(key);

  @override
  Future<void> clearAll() async {
    try {
      await _box.clear();
    } on Object catch (e, stack) {
      AppLogger.instance.error(
        'Failed to clear preferences storage',
        error: e,
        stackTrace: stack,
      );
      throw StorageException(
        message: 'Failed to clear storage',
        originalError: e,
        stackTrace: stack,
      );
    }
  }
}

/// Riverpod provider for the [StorageService].
///
/// Inject this wherever storage access is needed instead of using
/// the concrete [HiveStorageService] directly.
@riverpod
StorageService storageService(StorageServiceRef ref) {
  return HiveStorageService();
}
