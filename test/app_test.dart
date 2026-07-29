import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/app/app.dart';
import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';

class FakeStorageService implements StorageService {
  final Map<String, dynamic> _data = {};

  @override
  T? get<T>(String key) => _data[key] as T?;

  @override
  Future<void> put<T>(String key, T value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

void main() {
  testWidgets('App widget tree renders without errors', (tester) async {
    // Set a large screen size to prevent test font (Ahem) overflows.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
        ],
        child: const StrokeWarsApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // App renders — at minimum a MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
