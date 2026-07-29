import 'package:stroke_wars/core/utils/uuid.dart';

/// Strongly-typed wrapper around a match UUID string.
///
/// Using a distinct type prevents raw [String] IDs from being
/// confused with other identifiers at compile time.
class MatchId {
  /// Creates a [MatchId] with the provided [value].
  const MatchId(this.value);

  /// Generates a new random RFC 4122 v4 [MatchId].
  factory MatchId.generate() => MatchId(generateV4Uuid());

  /// Creates a [MatchId] from a JSON map.
  factory MatchId.fromJson(Map<String, dynamic> json) =>
      MatchId(json['value'] as String);

  /// The underlying UUID string.
  final String value;

  @override
  bool operator ==(Object other) => other is MatchId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MatchId($value)';

  /// Converts this [MatchId] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {'value': value};
}
