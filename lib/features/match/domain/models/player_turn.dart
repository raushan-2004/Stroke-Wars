/// Immutable historical snapshot of one player's drawing turn.
///
/// [PlayerTurn] records *what happened* during a turn for use in
/// replay, statistics, and analytics. Mutable rotation logic lives in
/// [TurnManager] — [PlayerTurn] is the audit trail it produces.
class PlayerTurn {
  /// Creates an immutable [PlayerTurn].
  const PlayerTurn({
    required this.roundNumber,
    required this.drawerId,
    required this.drawerDisplayName,
    required this.startedAt,
    this.endedAt,
    this.completed = false,
    this.skipped = false,
    this.wordsOffered = const [],
    this.wordChosenId,
  });

  /// Creates a [PlayerTurn] from a JSON map.
  factory PlayerTurn.fromJson(Map<String, dynamic> json) => PlayerTurn(
    roundNumber: json['roundNumber'] as int,
    drawerId: json['drawerId'] as String,
    drawerDisplayName: json['drawerDisplayName'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
    completed: json['completed'] as bool? ?? false,
    skipped: json['skipped'] as bool? ?? false,
    wordsOffered:
        (json['wordsOffered'] as List<dynamic>?)?.cast<String>() ?? const [],
    wordChosenId: json['wordChosenId'] as String?,
  );

  /// The round number this turn belongs to.
  final int roundNumber;

  /// UUID of the player who drew during this turn.
  final String drawerId;

  /// Display name of the drawer at turn time.
  final String drawerDisplayName;

  /// When the drawing phase started.
  final DateTime startedAt;

  /// When the drawing phase ended. Null if still in progress.
  final DateTime? endedAt;

  /// Whether this turn completed normally.
  final bool completed;

  /// Whether this turn was skipped (e.g. drawer disconnected).
  final bool skipped;

  /// IDs of words that were offered to the drawer.
  final List<String> wordsOffered;

  /// ID of the word the drawer chose. Null if the turn was skipped.
  final String? wordChosenId;

  /// Duration of this turn in milliseconds, or null if not yet ended.
  int? get durationMs => endedAt?.difference(startedAt).inMilliseconds;

  /// Returns a copy with the specified fields replaced.
  PlayerTurn copyWith({
    int? roundNumber,
    String? drawerId,
    String? drawerDisplayName,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? completed,
    bool? skipped,
    List<String>? wordsOffered,
    String? wordChosenId,
  }) => PlayerTurn(
    roundNumber: roundNumber ?? this.roundNumber,
    drawerId: drawerId ?? this.drawerId,
    drawerDisplayName: drawerDisplayName ?? this.drawerDisplayName,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    completed: completed ?? this.completed,
    skipped: skipped ?? this.skipped,
    wordsOffered: wordsOffered ?? this.wordsOffered,
    wordChosenId: wordChosenId ?? this.wordChosenId,
  );

  /// Converts this [PlayerTurn] to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'roundNumber': roundNumber,
    'drawerId': drawerId,
    'drawerDisplayName': drawerDisplayName,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'completed': completed,
    'skipped': skipped,
    'wordsOffered': wordsOffered,
    'wordChosenId': wordChosenId,
  };

  @override
  bool operator ==(Object other) =>
      other is PlayerTurn &&
      other.roundNumber == roundNumber &&
      other.drawerId == drawerId &&
      other.startedAt == startedAt;

  @override
  int get hashCode => Object.hash(roundNumber, drawerId, startedAt);

  @override
  String toString() =>
      'PlayerTurn(round=$roundNumber, drawer=$drawerDisplayName, '
      'completed=$completed, skipped=$skipped)';
}
