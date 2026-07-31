import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_bus.dart';
import 'package:stroke_wars/features/canvas/application/input/drawing_event_dispatcher.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/render_queue.dart';
import 'package:stroke_wars/features/match/application/clock_provider.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/application/match_validator.dart';
import 'package:stroke_wars/features/match/application/random_provider.dart';
import 'package:stroke_wars/features/match/application/rule_engine.dart';
import 'package:stroke_wars/features/match/application/scoring_engine.dart';
import 'package:stroke_wars/features/match/application/sequence_generator.dart';
import 'package:stroke_wars/features/match/application/word_selector.dart';
import 'package:stroke_wars/features/match/data/word_lists/default_word_list.dart';
import 'package:stroke_wars/features/profile/domain/models/match_history.dart';
import 'package:stroke_wars/features/replay/domain/models/replay_models.dart';
import 'package:stroke_wars/features/replay/application/replay_serializer.dart';
import 'package:stroke_wars/features/replay/application/replay_controller.dart';
import 'package:stroke_wars/features/replay/data/repositories/replay_repository.dart';
import 'package:stroke_wars/features/replay/data/repositories/match_history_repository.dart';

part 'replay_providers.g.dart';

@riverpod
ReplayRepository replayRepository(ReplayRepositoryRef ref) {
  return ReplayRepository();
}

@riverpod
MatchHistoryRepository matchHistoryRepository(MatchHistoryRepositoryRef ref) {
  return MatchHistoryRepository();
}

@riverpod
ReplaySerializer replaySerializer(ReplaySerializerRef ref) {
  return ReplaySerializer();
}

@riverpod
class MatchHistoryList extends _$MatchHistoryList {
  @override
  Future<List<MatchHistory>> build() async {
    return ref.watch(matchHistoryRepositoryProvider).getMatchHistory();
  }

  Future<void> addRecord(MatchHistory record) async {
    state = const AsyncLoading();
    await ref.read(matchHistoryRepositoryProvider).addMatchRecord(record);
    ref.invalidateSelf();
  }

  Future<void> clearAll() async {
    state = const AsyncLoading();
    await ref.read(matchHistoryRepositoryProvider).clearHistory();
    ref.invalidateSelf();
  }
}

/// Active Replay Controller provider.
@riverpod
class ActiveReplay extends _$ActiveReplay {
  ReplayController? _controller;

  @override
  Future<ReplaySession> build(String replayId) async {
    final repo = ref.watch(replayRepositoryProvider);
    final serializer = ref.watch(replaySerializerProvider);

    // 1. Lazy load full replay contents from disk
    final raw = await repo.loadReplay(replayId);
    final decoded = serializer.decodeReplay(raw);

    final metadata = decoded['metadata'] as ReplayMetadata;
    final eventLog = decoded['eventLog'] as ReplayEventLog;
    final checkpoints = decoded['checkpoints'] as List<ReplayCheckpoint>;
    final bookmarks = decoded['bookmarks'] as List<Bookmark>;

    // 2. Instantiate isolated engines for playback
    final matchEventBus = MatchEventBus();
    final matchController = MatchController(
      dispatcher: MatchEventDispatcher(bus: matchEventBus),
      validator: MatchValidator(),
      rules: RuleEngine(
        wordRules: const WordRules(),
        victoryRules: const VictoryRules(),
        configurationRules: const ConfigurationRules(),
      ),
      scoring: const ScoringEngine(),
      wordSelector: WordSelector(
        repository: const DefaultWordList(),
        random: DefaultRandomProvider(),
      ),
      clock: SystemClock(),
      sequenceGenerator: SequenceGenerator(),
    );

    final canvasController = CanvasController(
      renderQueue: RenderQueue(),
      dispatcher: DrawingEventDispatcher(eventBus: DrawingEventBus()),
    );

    // 3. Create controller
    _controller = ReplayController(
      matchController: matchController,
      canvasController: canvasController,
      metadata: metadata,
      eventLog: eventLog,
      checkpoints: checkpoints,
      bookmarks: bookmarks,
    );

    _controller!.addListener((updatedSession) {
      state = AsyncData(updatedSession);
    });

    ref.onDispose(() {
      _controller?.dispose();
    });

    return _controller!.session;
  }

  ReplayController? get controller => _controller;
}
