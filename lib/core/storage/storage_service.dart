/// Abstract contract for key-value local storage.
///
/// Implementations must be provided via Riverpod DI.
/// This abstraction allows swapping the storage backend (e.g., Hive → SQLite)
/// without touching business logic.
abstract interface class StorageService {
  /// Returns the value stored at [key], or null if absent.
  T? get<T>(String key);

  /// Stores [value] at [key].
  Future<void> put<T>(String key, T value);

  /// Removes the value at [key].
  Future<void> delete(String key);

  /// Returns true if [key] exists in storage.
  bool containsKey(String key);

  /// Removes all values from the primary preferences box.
  Future<void> clearAll();
}
