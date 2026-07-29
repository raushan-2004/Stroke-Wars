import 'package:stroke_wars/features/canvas/domain/models/stroke_point.dart';

/// Interface for predicting user coordinate drawing direction to counter sensor latency.
abstract interface class StrokePredictor {
  /// Predicts future coordinates based on current active points.
  List<StrokePoint> predict(List<StrokePoint> points);
}

/// Default empty predictor returning no predicted points.
class DefaultPredictor implements StrokePredictor {
  /// Creates a [DefaultPredictor].
  const DefaultPredictor();

  @override
  List<StrokePoint> predict(List<StrokePoint> points) => const [];
}
