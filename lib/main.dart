import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:stroke_wars/app/app.dart';
import 'package:stroke_wars/core/exceptions/app_exception.dart';
import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/core/storage/hive_storage_service.dart';

Future<void> main() async {
  await runZonedGuarded(_bootstrap, _onZoneError);
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureSystemUI();
  await _initializeHive();

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.instance.error(
      'Flutter error caught',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    AppLogger.instance.error(
      'Platform dispatcher error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  runApp(const ProviderScope(child: StrokeWarsApp()));
}

Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();
  await HiveStorageService.openRequiredBoxes();
}

void _onZoneError(Object error, StackTrace stack) {
  AppLogger.instance.error(
    'Unhandled zone error',
    error: error,
    stackTrace: stack,
  );

  if (error is! AppException) {
    // In production, report to crash analytics here.
  }
}
