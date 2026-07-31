import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/online/providers/online_providers.dart';
import 'package:stroke_wars/features/online_gameplay/application/online_game_controller.dart';
import 'package:stroke_wars/features/online_gameplay/domain/models/online_game_session.dart';

part 'online_game_providers.g.dart';

/// Riverpod notifier provider for the online gameplay session state.
@riverpod
class OnlineGameSessionStateNotifier extends _$OnlineGameSessionStateNotifier {
  late final OnlineGameController _controller;

  @override
  OnlineGameSession build() {
    final sessionNotifier = ref.watch(
      onlineSessionStateNotifierProvider.notifier,
    );
    final sessionController = sessionNotifier.controller;

    _controller = OnlineGameController(
      sessionController: sessionController,
      matchController: sessionController.matchController,
      canvasController: sessionController.canvasController,
      transport: sessionController.transport,
    );

    _controller.addListener((newSession) {
      state = newSession;
    });

    ref.onDispose(() {
      _controller.dispose();
    });

    return _controller.session;
  }

  /// Exposes the plain Dart [OnlineGameController] instance.
  OnlineGameController get controller => _controller;
}
