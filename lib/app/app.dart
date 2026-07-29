import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/app/router/app_router.dart';
import 'package:stroke_wars/app/theme/app_theme.dart';
import 'package:stroke_wars/core/services/theme_service.dart';

/// The root application widget for Stroke Wars.
class StrokeWarsApp extends ConsumerWidget {
  /// Creates the root [StrokeWarsApp].
  const StrokeWarsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final lightThemeData = ref.watch(lightThemeProvider);
    final darkThemeData = ref.watch(darkThemeProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Stroke Wars',
          debugShowCheckedModeBanner: false,
          theme: lightThemeData,
          darkTheme: darkThemeData,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
