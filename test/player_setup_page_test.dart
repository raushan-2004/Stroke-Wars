import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';
import 'package:stroke_wars/features/profile/presentation/player_setup_page.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

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
  testWidgets('PlayerSetupPage renders and allows step navigation', (
    WidgetTester tester,
  ) async {
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
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) =>
              const MaterialApp(home: PlayerSetupPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial Onboarding Welcome title and avatars grid
    expect(find.text('CHOOSE AVATAR'), findsOneWidget);
    expect(
      find.text('Select a built-in character to represent you.'),
      findsOneWidget,
    );
    expect(find.byType(SWPressableScale), findsAtLeast(8)); // avatar chips

    // Verify presence of Continue Button
    expect(find.text('CONTINUE'), findsOneWidget);

    // Tap Continue to proceed to Step 1 (Display Name)
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR NAME'), findsOneWidget);
    expect(find.text('RANDOM NAME'), findsOneWidget);
    expect(find.byType(SWTextField), findsOneWidget);

    // Tap Continue to proceed to Step 2 (Theme/Accent)
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(find.text('SELECT THEME'), findsOneWidget);
    expect(find.text('FAVORITE ACCENT COLOR'), findsOneWidget);
  });
}
