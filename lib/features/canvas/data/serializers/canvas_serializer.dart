import 'dart:convert';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';

/// Serialization helper translating entire canvas stroke list databases.
class CanvasSerializer {
  CanvasSerializer._();

  /// Converts a list of strokes to a JSON String.
  static String serialize(List<Stroke> strokes) {
    final list = strokes.map((s) => s.toJson()).toList();
    return json.encode(list);
  }

  /// Restores a list of strokes from a JSON String.
  static List<Stroke> deserialize(String data) {
    final decoded = json.decode(data) as List<dynamic>;
    return decoded
        .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
        .toList();
  }
}
