import 'dart:convert';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';

/// Serialization helper translating [Stroke] objects.
class StrokeSerializer {
  StrokeSerializer._();

  /// Converts a [Stroke] to a JSON String.
  static String serialize(Stroke stroke) => json.encode(stroke.toJson());

  /// Restores a [Stroke] from a JSON String.
  static Stroke deserialize(String data) =>
      Stroke.fromJson(json.decode(data) as Map<String, dynamic>);
}
