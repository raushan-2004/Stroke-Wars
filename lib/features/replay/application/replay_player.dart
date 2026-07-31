import 'dart:async';
import 'dart:ui';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/match/domain/models/match.dart'
    as gameplay;
import 'package:stroke_wars/features/match/domain/models/match_state.dart';
import 'package:stroke_wars/features/match/domain/models/round.dart';
import 'package:stroke_wars/features/match/domain/models/round_state.dart';
import 'package:stroke_wars/features/match/domain/models/timer_state.dart';
import 'package:stroke_wars/features/match/domain/models/word.dart';
import 'package:stroke_wars/features/match/domain/models/word_category.dart';
import 'package:stroke_wars/features/match/domain/models/word_difficulty.dart';
import 'package:stroke_wars/features/match/domain/models/round_id.dart';
import 'package:stroke_wars/features/match/domain/models/round_configuration.dart';
import 'package:stroke_wars/features/replay/domain/models/replay_models.dart';

/// Active player driving match playback loops, timeline seeking, and checkpoints.
class ReplayPlayer {
  ReplayPlayer({
    required this.matchController,
    required this.canvasController,
    required this.metadata,
    required this.eventLog,
    required this.checkpoints,
    required this.bookmarks,
    required this.onSessionUpdated,
  }) {
    _session = ReplaySession(
      replayId: ReplayId(DateTime.now().millisecondsSinceEpoch.toString()),
      matchId: metadata.playerList.isNotEmpty ? 'match' : '1',
      players: metadata.playerList,
      metadata: metadata,
      currentFrame: 0,
      playbackState: PlaybackState.ready,
      playbackSpeed: 1.0,
      duration: metadata.duration,
      bookmarks: bookmarks,
    );
  }

  final MatchController matchController;
  final CanvasController canvasController;
  final ReplayMetadata metadata;
  final ReplayEventLog eventLog;
  final List<ReplayCheckpoint> checkpoints;
  final List<Bookmark> bookmarks;
  final void Function(ReplaySession) onSessionUpdated;

  late ReplaySession _session;
  ReplaySession get session => _session;

  Timer? _playbackTimer;
  int _currentTimeMs = 0;
  final List<Map<String, dynamic>> _replayChatHistory = [];
  List<Map<String, dynamic>> get chatHistory => _replayChatHistory;

  /// Starts playback loop.
  void play() {
    if (_session.playbackState == PlaybackState.playing) return;
    _updateState(_session.copyWith(playbackState: PlaybackState.playing));

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final step = (50 * _session.playbackSpeed).toInt();
      _currentTimeMs += step;

      if (_currentTimeMs >= _session.duration.inMilliseconds) {
        _currentTimeMs = _session.duration.inMilliseconds;
        _updateState(
          _session.copyWith(
            playbackState: PlaybackState.finished,
            currentFrame: _currentTimeMs,
          ),
        );
        timer.cancel();
      } else {
        _applyEventsUpTo(_currentTimeMs);
        _updateState(_session.copyWith(currentFrame: _currentTimeMs));
      }
    });
  }

  /// Pauses playback.
  void pause() {
    _playbackTimer?.cancel();
    _updateState(_session.copyWith(playbackState: PlaybackState.paused));
  }

  /// Resumes playback.
  void resume() {
    play();
  }

  /// Restarts replay from offset 0.
  void restart() {
    seekTo(0);
    play();
  }

  /// Steps forward by 100ms.
  void stepForward() {
    pause();
    var target = _currentTimeMs + 100;
    if (target > _session.duration.inMilliseconds) {
      target = _session.duration.inMilliseconds;
    }
    seekTo(target);
  }

  /// Steps backward by 100ms.
  void stepBackward() {
    pause();
    var target = _currentTimeMs - 100;
    if (target < 0) target = 0;
    seekTo(target);
  }

  /// Seeks to a specific millisecond offset using nearest checkpoint + fast forward.
  void seekTo(int targetMs) {
    final wasPlaying = _session.playbackState == PlaybackState.playing;
    pause();

    _updateState(_session.copyWith(playbackState: PlaybackState.seeking));

    // 1. Find nearest checkpoint
    ReplayCheckpoint? nearest;
    for (final cp in checkpoints) {
      if (cp.timestampOffsetMs <= targetMs) {
        if (nearest == null ||
            cp.timestampOffsetMs > nearest.timestampOffsetMs) {
          nearest = cp;
        }
      }
    }

    _replayChatHistory.clear();

    // 2. Restore state
    if (nearest != null) {
      final restoredMatch = gameplay.Match.fromJson(nearest.matchStateJson);
      matchController.match = restoredMatch;

      canvasController.resetHistory();
      for (final drawingJson in nearest.drawingEventsJson) {
        _applyDrawingJson(drawingJson);
      }
      _currentTimeMs = nearest.timestampOffsetMs;
    } else {
      matchController.match = null;
      canvasController.resetHistory();
      _currentTimeMs = 0;
    }

    // 3. Fast forward remaining events
    _applyEventsUpTo(targetMs);

    _currentTimeMs = targetMs;
    _updateState(
      _session.copyWith(
        playbackState: wasPlaying
            ? PlaybackState.playing
            : PlaybackState.paused,
        currentFrame: _currentTimeMs,
      ),
    );

    if (wasPlaying) {
      play();
    }
  }

  /// Sets playback speed.
  void setSpeed(double speed) {
    final wasPlaying = _session.playbackState == PlaybackState.playing;
    _session = _session.copyWith(playbackSpeed: speed);
    if (wasPlaying) {
      pause();
      play();
    } else {
      _updateState(_session);
    }
  }

  void _applyEventsUpTo(int targetMs) {
    final events = eventLog.events.where(
      (e) =>
          e.timestampOffsetMs > _currentTimeMs &&
          e.timestampOffsetMs <= targetMs,
    );

    for (final event in events) {
      if (event.type == 'match') {
        _applyMatchEventJson(event.payload);
      } else if (event.type == 'drawing') {
        _applyDrawingJson(event.payload);
      } else if (event.type == 'chat') {
        _replayChatHistory.add(event.payload);
      }
    }
  }

  void _applyDrawingJson(Map<String, dynamic> json) {
    try {
      final event = DrawingEvent.fromJson(json);
      _applyDrawingEvent(event);
    } catch (_) {}
  }

  void _applyDrawingEvent(DrawingEvent event) {
    if (event is StrokeStarted) {
      final clean = event.color.replaceAll('#', '');
      final color = clean.length == 6
          ? Color(int.parse('FF$clean', radix: 16))
          : Color(int.parse(clean, radix: 16));

      canvasController.startStroke(
        event.playerId,
        canvasController.state.selectedBrush.copyWith(
          color: color,
          size: event.width,
          opacity: event.opacity,
        ),
      );
    } else if (event is PointAdded) {
      canvasController.appendPoint(
        event.point.x,
        event.point.y,
        pressure: event.point.pressure,
        velocity: event.point.velocity,
      );
    } else if (event is StrokeFinished) {
      canvasController.finishStroke();
    } else if (event is CanvasCleared) {
      canvasController.clear();
    } else if (event is UndoPerformed) {
      canvasController.undo();
    } else if (event is RedoPerformed) {
      canvasController.redo();
    }
  }

  void _applyMatchEventJson(Map<String, dynamic> json) {
    try {
      final event = MatchEvent.fromJson(json);
      final match = matchController.match;
      if (match == null) return;

      if (event is TimerTickEvent) {
        if (match.rounds.isNotEmpty) {
          final current = match.rounds.last;
          final updated = current.copyWith(
            timerState: TimerState(
              durationSecs: current.timerState?.durationSecs ?? 60,
              elapsedSecs:
                  (current.timerState?.durationSecs ?? 60) -
                  event.remainingSecs,
            ),
          );
          final list = List<Round>.from(match.rounds)
            ..removeLast()
            ..add(updated);
          matchController.match = match.copyWith(rounds: list);
        }
      } else if (event is ScoreUpdatedEvent) {
        final list = match.players.map((p) {
          if (p.playerId == event.playerId) {
            return p.copyWith(totalScore: event.newTotal);
          }
          return p;
        }).toList();
        matchController.match = match.copyWith(players: list);
      } else if (event is RoundStartedEvent) {
        final newRound = Round(
          id: RoundId(event.roundId ?? 'round-${event.roundNumber}'),
          matchId: match.id,
          roundNumber: event.roundNumber,
          state: const RoundActiveState(),
          drawerSlotId: event.drawerId,
          configuration: const RoundConfiguration(drawTimeSecs: 60),
          timerState: null,
          guesses: const [],
          scores: const [],
        );
        final list = List<Round>.from(match.rounds)..add(newRound);
        matchController.match = match.copyWith(
          rounds: list,
          currentRoundIndex: event.roundNumber - 1,
          state: const DrawingState(),
        );
      } else if (event is RoundEndedEvent) {
        matchController.match = match.copyWith(
          state: const RoundFinishedState(),
        );
      } else if (event is WordChosenEvent) {
        if (match.rounds.isNotEmpty) {
          final current = match.rounds.last;
          final updated = current.copyWith(
            word: Word(
              id: event.wordId,
              text: '',
              difficulty: WordDifficulty.medium,
              category: WordCategory.objects,
            ),
          );
          final list = List<Round>.from(match.rounds)
            ..removeLast()
            ..add(updated);
          matchController.match = match.copyWith(rounds: list);
        }
      } else if (event is WordRevealedEvent) {
        if (match.rounds.isNotEmpty) {
          final current = match.rounds.last;
          final updated = current.copyWith(
            word: Word(
              id: current.word?.id ?? 'word',
              text: event.wordText,
              difficulty: WordDifficulty.medium,
              category: WordCategory.objects,
            ),
          );
          final list = List<Round>.from(match.rounds)
            ..removeLast()
            ..add(updated);
          matchController.match = match.copyWith(rounds: list);
        }
      } else if (event is MatchStartedEvent) {
        matchController.match = match.copyWith(
          state: const MatchStartingState(),
        );
      } else if (event is MatchEndedEvent) {
        matchController.match = match.copyWith(
          state: const MatchFinishedState(),
        );
      } else if (event is MatchCancelledEvent) {
        matchController.match = match.copyWith(
          state: const MatchCancelledState(),
        );
      }
    } catch (_) {}
  }

  void _updateState(ReplaySession newState) {
    _session = newState;
    onSessionUpdated(newState);
  }

  void dispose() {
    _playbackTimer?.cancel();
  }
}
