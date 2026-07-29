import 'package:stroke_wars/core/utils/uuid.dart';

/// Strongly-typed wrapper around a round UUID string.
class RoundId {
  /// Creates a [RoundId] with the provided [value].
  const RoundId(this.value);

  /// Generates a new random RFC 4122 v4 [RoundId].
  factory RoundId.generate() => RoundId(generateV4Uuid());

  /// Creates a [RoundId] from a JSON map.
  factory RoundId.fromJson(Map<String, dynamic> json) =>
      RoundId(json['value'] as String);

  /// The underlying UUID string.
  final String value;

  @override
  bool operator ==(Object other) => other is RoundId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RoundId($value)';

  /// Converts this [RoundId] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {'value': value};
}
