import 'package:stroke_wars/features/canvas/domain/models/input/input_event.dart';

/// Strategy pattern interface responsible for rejecting accidental palm touches during drawing.
abstract interface class PalmRejectionStrategy {
  /// Evaluates whether an event should be ignored.
  bool shouldReject(InputEvent event);
}

/// Default strategy accepting all pointer events.
class DefaultStrategy implements PalmRejectionStrategy {
  /// Creates a [DefaultStrategy].
  const DefaultStrategy();

  @override
  bool shouldReject(InputEvent event) => false;
}

/// Stylus strategy preparing for palm rejection when a pen digitizer is active (placeholder).
class StylusPalmRejectionStrategy implements PalmRejectionStrategy {
  /// Creates a [StylusPalmRejectionStrategy].
  const StylusPalmRejectionStrategy();

  @override
  bool shouldReject(InputEvent event) => false;
}
