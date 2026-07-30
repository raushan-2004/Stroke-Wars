/// Immutable data model containing statistics tracked during a Practice Mode session.
class PracticeStatistics {
  /// Creates a [PracticeStatistics] instance.
  const PracticeStatistics({
    this.strokeCount = 0,
    this.averageStrokeLength = 0.0,
    this.brushUsage = const {},
    this.undoCount = 0,
    this.redoCount = 0,
    this.averageRoundDuration = 0.0,
    this.pauseCount = 0,
    this.drawingDuration = 0.0,
    this.idleDuration = 0.0,
    this.totalPointsPerStroke = 0,
    this.totalRoundsCompleted = 0,
    this.totalRoundTimeSecs = 0,
  });

  /// Total number of individual strokes completed.
  final int strokeCount;

  /// Average number of points per stroke.
  final double averageStrokeLength;

  /// Frequency map of brush type names used.
  final Map<String, int> brushUsage;

  /// Total undo operations performed.
  final int undoCount;

  /// Total redo operations performed.
  final int redoCount;

  /// Average round duration in seconds.
  final double averageRoundDuration;

  /// Number of times the session was paused.
  final int pauseCount;

  /// Total cumulative seconds spent drawing.
  final double drawingDuration;

  /// Total cumulative seconds spent in pre-round word selection or preparation.
  final double idleDuration;

  /// Helper accumulators to maintain running averages without loss of precision.
  final int totalPointsPerStroke;
  final int totalRoundsCompleted;
  final int totalRoundTimeSecs;

  /// Creates a copy of this statistics model with updated properties.
  PracticeStatistics copyWith({
    int? strokeCount,
    double? averageStrokeLength,
    Map<String, int>? brushUsage,
    int? undoCount,
    int? redoCount,
    double? averageRoundDuration,
    int? pauseCount,
    double? drawingDuration,
    double? idleDuration,
    int? totalPointsPerStroke,
    int? totalRoundsCompleted,
    int? totalRoundTimeSecs,
  }) {
    return PracticeStatistics(
      strokeCount: strokeCount ?? this.strokeCount,
      averageStrokeLength: averageStrokeLength ?? this.averageStrokeLength,
      brushUsage: brushUsage ?? this.brushUsage,
      undoCount: undoCount ?? this.undoCount,
      redoCount: redoCount ?? this.redoCount,
      averageRoundDuration: averageRoundDuration ?? this.averageRoundDuration,
      pauseCount: pauseCount ?? this.pauseCount,
      drawingDuration: drawingDuration ?? this.drawingDuration,
      idleDuration: idleDuration ?? this.idleDuration,
      totalPointsPerStroke: totalPointsPerStroke ?? this.totalPointsPerStroke,
      totalRoundsCompleted: totalRoundsCompleted ?? this.totalRoundsCompleted,
      totalRoundTimeSecs: totalRoundTimeSecs ?? this.totalRoundTimeSecs,
    );
  }

  /// Converts statistics to a JSON Map.
  Map<String, dynamic> toJson() => {
        'strokeCount': strokeCount,
        'averageStrokeLength': averageStrokeLength,
        'brushUsage': brushUsage,
        'undoCount': undoCount,
        'redoCount': redoCount,
        'averageRoundDuration': averageRoundDuration,
        'pauseCount': pauseCount,
        'drawingDuration': drawingDuration,
        'idleDuration': idleDuration,
        'totalPointsPerStroke': totalPointsPerStroke,
        'totalRoundsCompleted': totalRoundsCompleted,
        'totalRoundTimeSecs': totalRoundTimeSecs,
      };

  /// Restores statistics from a JSON Map.
  factory PracticeStatistics.fromJson(Map<String, dynamic> json) =>
      PracticeStatistics(
        strokeCount: json['strokeCount'] as int? ?? 0,
        averageStrokeLength:
            (json['averageStrokeLength'] as num? ?? 0.0).toDouble(),
        brushUsage: Map<String, int>.from(json['brushUsage'] as Map? ?? const {}),
        undoCount: json['undoCount'] as int? ?? 0,
        redoCount: json['redoCount'] as int? ?? 0,
        averageRoundDuration:
            (json['averageRoundDuration'] as num? ?? 0.0).toDouble(),
        pauseCount: json['pauseCount'] as int? ?? 0,
        drawingDuration: (json['drawingDuration'] as num? ?? 0.0).toDouble(),
        idleDuration: (json['idleDuration'] as num? ?? 0.0).toDouble(),
        totalPointsPerStroke: json['totalPointsPerStroke'] as int? ?? 0,
        totalRoundsCompleted: json['totalRoundsCompleted'] as int? ?? 0,
        totalRoundTimeSecs: json['totalRoundTimeSecs'] as int? ?? 0,
      );
}
