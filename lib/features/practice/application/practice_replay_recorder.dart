import 'dart:convert';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/match/domain/events/match_event.dart';

/// Records granular timeline logs of match and drawing events during practice.
class PracticeReplayRecorder {
  final List<Map<String, dynamic>> _records = [];

  /// Retrieves an unmodifiable copy of all recorded timeline entries.
  List<Map<String, dynamic>> get records => List.unmodifiable(_records);

  /// Records a single [MatchEvent] entry with timestamps.
  void recordMatchEvent(MatchEvent event, DateTime timestamp) {
    _records.add({
      'type': 'match_event',
      'timestamp': timestamp.millisecondsSinceEpoch,
      'event': event.toJson(),
    });
  }

  /// Records a single [DrawingEvent] entry with timestamps.
  void recordDrawingEvent(DrawingEvent event, DateTime timestamp) {
    _records.add({
      'type': 'drawing_event',
      'timestamp': timestamp.millisecondsSinceEpoch,
      'event': event.toJson(),
    });
  }

  /// Records state machine transition milestones.
  void recordRoundTransition(String fromState, String toState, DateTime timestamp) {
    _records.add({
      'type': 'round_transition',
      'timestamp': timestamp.millisecondsSinceEpoch,
      'from': fromState,
      'to': toState,
    });
  }

  /// Converts the complete timeline of recorded entries to a JSON String.
  String serialize() {
    return json.encode(_records);
  }

  /// Resets the timeline records.
  void clear() {
    _records.clear();
  }
}
