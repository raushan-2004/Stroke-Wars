import 'dart:async';
import 'package:stroke_wars/features/canvas/application/canvas_controller.dart';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/application/match_controller.dart';
import 'package:stroke_wars/features/match/application/match_event_bus.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';
import 'package:stroke_wars/features/profile/domain/models/match_history.dart';
import 'package:stroke_wars/features/replay/domain/models/replay_models.dart';
import 'package:stroke_wars/features/replay/application/replay_serializer.dart';
import 'package:stroke_wars/features/replay/data/repositories/replay_repository.dart';
import 'package:stroke_wars/features/replay/data/repositories/match_history_repository.dart';

/// Recorder passively capturing MatchEvents, DrawingEvents, and Chat messages to construct replay logs.
class MatchEventRecorder {
  MatchEventRecorder({
    required this.matchController,
    required this.canvasController,
    required this.matchEventBus,
    required this.drawingEventBus,
    ReplayRepository? replayRepository,
    MatchHistoryRepository? historyRepository,
    ReplaySerializer? serializer,
  }) : _replayRepo = replayRepository ?? ReplayRepository(),
       _historyRepo = historyRepository ?? MatchHistoryRepository(),
       _serializer = serializer ?? ReplaySerializer();

  final MatchController matchController;
  final CanvasController canvasController;
  final MatchEventBus matchEventBus;
  final dynamic drawingEventBus; // Support different bus types cleanly

  final ReplayRepository _replayRepo;
  final MatchHistoryRepository _historyRepo;
  final ReplaySerializer _serializer;

  StreamSubscription<MatchEvent>? _matchSub;
  StreamSubscription<DrawingEvent>? _drawingSub;
  Timer? _checkpointTimer;

  DateTime? _matchStartTime;
  bool _isRecording = false;

  final List<ReplayEvent> _events = [];
  final List<ReplayCheckpoint> _checkpoints = [];
  final List<Bookmark> _bookmarks = [];
  final List<Map<String, dynamic>> _drawingLog = [];

  bool get isRecording => _isRecording;

  /// Begins listening to gameplay event streams.
  void start() {
    if (_isRecording) return;
    _isRecording = true;
    _events.clear();
    _checkpoints.clear();
    _bookmarks.clear();
    _drawingLog.clear();

    _matchSub = matchEventBus.stream.listen(_handleMatchEvent);

    if (drawingEventBus != null) {
      try {
        _drawingSub = drawingEventBus.stream.listen(_handleDrawingEvent);
      } catch (_) {}
    }

    _checkpointTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _generateCheckpoint(),
    );
  }

  /// Manually stops recording and cleans up stream listeners.
  void stop() {
    _isRecording = false;
    _matchSub?.cancel();
    _drawingSub?.cancel();
    _checkpointTimer?.cancel();
  }

  void _handleMatchEvent(MatchEvent event) {
    if (_matchStartTime == null) {
      if (event is MatchCreatedEvent || event is MatchStartedEvent) {
        _matchStartTime = event.timestamp;
        _generateCheckpoint(); // Initial checkpoint at offset 0
      } else {
        _matchStartTime = DateTime.now();
      }
    }

    final offsetMs = event.timestamp
        .difference(_matchStartTime!)
        .inMilliseconds;

    // Convert MatchEvent to JSON payload
    final payload = event.toJson();
    payload['type'] = _getMatchEventTypeString(event);

    _events.add(
      ReplayEvent(
        sequenceNumber: event.sequenceNumber,
        timestampOffsetMs: offsetMs,
        type: 'match',
        payload: payload,
      ),
    );

    // Handle Bookmarks
    _evaluateBookmarks(event, offsetMs);

    // Handle final match ending
    if (event is MatchEndedEvent) {
      _saveReplay(event.winnerId);
    } else if (event is MatchCancelledEvent) {
      _saveReplay('cancelled');
    }
  }

  void _handleDrawingEvent(DrawingEvent event) {
    if (_matchStartTime == null) return;
    final offsetMs = DateTime.now().difference(_matchStartTime!).inMilliseconds;

    final json = event.toJson();
    _drawingLog.add(json);

    _events.add(
      ReplayEvent(
        sequenceNumber: _events.length + 1,
        timestampOffsetMs: offsetMs,
        type: 'drawing',
        payload: json,
      ),
    );
  }

  /// Appends a custom chat message event to the replay timeline.
  void recordChatMessage(String senderName, String text) {
    if (!_isRecording || _matchStartTime == null) return;
    final offsetMs = DateTime.now().difference(_matchStartTime!).inMilliseconds;

    _events.add(
      ReplayEvent(
        sequenceNumber: _events.length + 1,
        timestampOffsetMs: offsetMs,
        type: 'chat',
        payload: {'senderName': senderName, 'text': text},
      ),
    );
  }

  void _evaluateBookmarks(MatchEvent event, int offsetMs) {
    if (event is RoundStartedEvent) {
      final total = matchController.match?.configuration.totalRounds ?? 3;
      if (event.roundNumber == total) {
        _bookmarks.add(
          Bookmark(
            title: 'Final Round',
            timestampOffsetMs: offsetMs,
            description: 'Round ${event.roundNumber} (Final Round) started',
          ),
        );
      } else {
        _bookmarks.add(
          Bookmark(
            title: 'Round Start',
            timestampOffsetMs: offsetMs,
            description: 'Round ${event.roundNumber} started',
          ),
        );
      }
    } else if (event is CorrectGuessEvent) {
      _bookmarks.add(
        Bookmark(
          title: 'Correct Guess',
          timestampOffsetMs: offsetMs,
          description: '${event.playerId} guessed the word correctly!',
        ),
      );
    } else if (event is WordRevealedEvent) {
      _bookmarks.add(
        Bookmark(
          title: 'Word Reveal',
          timestampOffsetMs: offsetMs,
          description: 'Word was revealed: ${event.wordText}',
        ),
      );
    } else if (event is MatchEndedEvent) {
      _bookmarks.add(
        Bookmark(
          title: 'Winner Announcement',
          timestampOffsetMs: offsetMs,
          description: 'Winner announced: ${event.winnerId}',
        ),
      );
    }
  }

  void _generateCheckpoint() {
    final match = matchController.match;
    if (match == null || _matchStartTime == null) return;

    final offsetMs = DateTime.now().difference(_matchStartTime!).inMilliseconds;

    // Snapshot current scoreboard
    final Map<String, int> scoreboard = {};
    for (final player in match.players) {
      scoreboard[player.playerId] = player.totalScore;
    }

    _checkpoints.add(
      ReplayCheckpoint(
        sequenceNumber: _events.length,
        timestampOffsetMs: offsetMs,
        matchStateJson: match.toJson(),
        drawingEventsJson: List.from(_drawingLog),
        scoreboard: scoreboard,
        roundNumber: match.currentRoundIndex + 1,
      ),
    );
  }

  Future<void> _saveReplay(String winner) async {
    stop();

    final match = matchController.match;
    if (match == null || _matchStartTime == null) return;

    final end = DateTime.now();
    final duration = end.difference(_matchStartTime!);

    final metadata = ReplayMetadata(
      matchStartTime: _matchStartTime!,
      matchEndTime: end,
      duration: duration,
      winner: winner,
      finalScores: _checkpoints.isNotEmpty ? _checkpoints.last.scoreboard : {},
      playerList: match.players.map((p) => p.displayName).toList(),
      gameMode: 'offline',
      integrity: const ReplayIntegrity(
        replayVersion: 1,
        engineVersion: '1.0.0',
        protocolVersion: 1,
        checksum: '',
      ),
    );

    final serialized = _serializer.encodeReplay(
      metadata: metadata,
      eventLog: ReplayEventLog(events: _events),
      checkpoints: _checkpoints,
      bookmarks: _bookmarks,
    );

    final replayId = match.id.value;
    await _replayRepo.saveReplay(replayId, serialized);

    // Save to match history independently
    await _historyRepo.addMatchRecord(
      MatchHistory(
        matchId: replayId,
        playedAt: _matchStartTime!,
        duration: duration.inSeconds,
        gameMode: 'offline',
        winner: winner,
        xpEarned: 100, // Fixed mock XP
      ),
    );
  }

  String _getMatchEventTypeString(MatchEvent event) {
    return switch (event) {
      MatchCreatedEvent() => 'match_created',
      MatchStartedEvent() => 'match_started',
      MatchEndedEvent() => 'match_ended',
      MatchCancelledEvent() => 'match_cancelled',
      PlayerJoinedEvent() => 'player_joined',
      PlayerLeftEvent() => 'player_left',
      PlayerSkippedEvent() => 'player_skipped',
      PlayerReadinessEvent() => 'player_readiness',
      RoundStartedEvent() => 'round_started',
      RoundEndedEvent() => 'round_ended',
      WordChosenEvent() => 'word_chosen',
      WordRevealedEvent() => 'word_revealed',
      GuessSubmittedEvent() => 'guess_submitted',
      CorrectGuessEvent() => 'correct_guess',
      TimerTickEvent() => 'timer_tick',
      TimerExpiredEvent() => 'timer_expired',
      ScoreUpdatedEvent() => 'score_updated',
    };
  }
}
