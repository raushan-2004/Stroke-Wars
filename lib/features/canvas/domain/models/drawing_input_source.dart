/// Defines the origin pointer source responsible for drawing strokes.
enum DrawingInputSource {
  /// Finger gesture inputs on capacitive touch displays.
  touch,

  /// Digitizer pressure/tilt stylus pen inputs.
  stylus,

  /// Desktop mouse cursor pointer coordinates.
  mouse,
}
