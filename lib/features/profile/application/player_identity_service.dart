import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/core/storage/hive_storage_service.dart';

part 'player_identity_service.g.dart';

/// Key used to store the device UUID in preferences.
const String _deviceUuidKey = 'device_unique_identity_uuid';

/// Service responsible for managing the persistent device UUID.
@riverpod
class PlayerIdentityService extends _$PlayerIdentityService {
  @override
  void build() {}

  /// Retrieves the existing UUID or generates and persists a new one.
  String getOrCreateUuid() {
    final storage = ref.read(storageServiceProvider);
    final existing = storage.get<String>(_deviceUuidKey);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newUuid = _generateV4Uuid();
    // Synchronous trigger for storage write task
    storage.put<String>(_deviceUuidKey, newUuid);
    return newUuid;
  }

  /// Generates a RFC4122 compliant Version 4 UUID.
  String _generateV4Uuid() {
    final random = Random.secure();
    String hexDigit(int value) => value.toRadixString(16);
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        buffer.write('-');
      }
      if (i == 12) {
        buffer.write('4'); // Version 4
      } else if (i == 16) {
        // Variant (8, 9, A, or B)
        buffer.write(hexDigit(random.nextInt(4) + 8));
      } else {
        buffer.write(hexDigit(random.nextInt(16)));
      }
    }
    return buffer.toString();
  }
}
