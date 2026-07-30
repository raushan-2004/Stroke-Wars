import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/core/storage/storage_service.dart';
import 'package:stroke_wars/core/storage/hive_storage_service.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/features/practice/application/practice_mode_controller.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_session.dart';

part 'practice_providers.g.dart';

/// Riverpod provider adapter for accessing the [PracticeModeController] and its active [PracticeSession] state.
@riverpod
class PracticeSessionState extends _$PracticeSessionState {
  late final PracticeModeController _controller;

  @override
  PracticeSession? build() {
    final storage = ref.watch(storageServiceProvider);
    final canvas = ref.watch(canvasControllerProvider);
    final drawingBus = ref.watch(drawingEventBusProvider);
    final player = ref.watch(playerServiceProvider);

    final humanId = player?.uuid ?? 'practice-bot';
    final humanName = player?.displayName ?? 'Player';

    _controller = PracticeModeController(
      storage: storage,
      canvasController: canvas,
      drawingBus: drawingBus,
      humanPlayerId: humanId,
      humanDisplayName: humanName,
    );

    _controller.addListener((newSession) {
      state = newSession;
    });

    ref.onDispose(() {
      _controller.dispose();
    });

    return _controller.session;
  }

  /// Exposes the plain Dart [PracticeModeController] instance.
  PracticeModeController get controller => _controller;
}
