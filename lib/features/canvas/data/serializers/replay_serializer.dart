import 'dart:convert';
import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';

/// Serialization helper translating Replay and network packet lists of [DrawingEvent] objects.
class ReplaySerializer {
  ReplaySerializer._();

  /// Converts a stream history of drawing events to a JSON String.
  static String serialize(List<DrawingEvent> events) {
    final list = events.map((e) => e.toJson()).toList();
    return json.encode(list);
  }

  /// Restores a stream history of drawing events from a JSON String.
  static List<DrawingEvent> deserialize(String data) {
    final decoded = json.decode(data) as List<dynamic>;
    return decoded
        .map((e) => DrawingEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
