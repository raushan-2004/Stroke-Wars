import 'package:stroke_wars/features/canvas/domain/models/brush_settings.dart';
import 'package:stroke_wars/features/canvas/domain/repositories/brush_renderer.dart';

/// Registry mapping BrushType definitions to concrete path rendering implementations.
class BrushRegistry {
  BrushRegistry._();

  static final Map<BrushType, BrushRenderer> _registry = {
    BrushType.classic: const ClassicBrushRenderer(),
    BrushType.marker: const MarkerBrushRenderer(),
    BrushType.neon: const NeonBrushRenderer(),
    BrushType.pencil: const ClassicBrushRenderer(),
    BrushType.pixel: const PixelBrushRenderer(),
    BrushType.airbrush: const AirbrushBrushRenderer(),
  };

  /// Fetches the draw strategy renderer associated with this brush style.
  static BrushRenderer getRenderer(BrushType type) {
    return _registry[type] ?? const ClassicBrushRenderer();
  }
}
