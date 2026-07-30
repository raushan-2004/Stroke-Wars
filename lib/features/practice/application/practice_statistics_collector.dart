import 'package:stroke_wars/features/canvas/domain/models/drawing_event.dart';
import 'package:stroke_wars/features/practice/domain/models/practice_statistics.dart';

/// Pure-function stats collector mapping canvas and match events to [PracticeStatistics].
class PracticeStatisticsCollector {
  /// Creates a [PracticeStatisticsCollector].
  const PracticeStatisticsCollector();

  /// Processes drawing events and updates stroke-specific totals.
  PracticeStatistics processDrawingEvent(PracticeStatistics stats, DrawingEvent event) {
    if (event is StrokeStarted) {
      final usage = Map<String, int>.from(stats.brushUsage);
      usage[event.brushId] = (usage[event.brushId] ?? 0) + 1;
      return stats.copyWith(
        brushUsage: usage,
        strokeCount: stats.strokeCount + 1,
      );
    } else if (event is PointAdded) {
      final totalPoints = stats.totalPointsPerStroke + 1;
      final avg = stats.strokeCount > 0 ? totalPoints / stats.strokeCount : 0.0;
      return stats.copyWith(
        totalPointsPerStroke: totalPoints,
        averageStrokeLength: avg,
      );
    } else if (event is UndoPerformed) {
      return stats.copyWith(undoCount: stats.undoCount + 1);
    } else if (event is RedoPerformed) {
      return stats.copyWith(redoCount: stats.redoCount + 1);
    }
    return stats;
  }

  /// Accumulates active and idle timings.
  PracticeStatistics processTimeTick(PracticeStatistics stats, double deltaSecs, bool isDrawing) {
    if (isDrawing) {
      return stats.copyWith(drawingDuration: stats.drawingDuration + deltaSecs);
    } else {
      return stats.copyWith(idleDuration: stats.idleDuration + deltaSecs);
    }
  }

  /// Records round duration metrics when a round completes.
  PracticeStatistics processRoundCompletion(PracticeStatistics stats, int roundDurationSecs) {
    final completed = stats.totalRoundsCompleted + 1;
    final totalTime = stats.totalRoundTimeSecs + roundDurationSecs;
    return stats.copyWith(
      totalRoundsCompleted: completed,
      totalRoundTimeSecs: totalTime,
      averageRoundDuration: totalTime / completed,
    );
  }

  /// Increments the pause counter.
  PracticeStatistics processPause(PracticeStatistics stats) {
    return stats.copyWith(pauseCount: stats.pauseCount + 1);
  }
}
