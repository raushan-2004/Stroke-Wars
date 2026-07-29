import 'package:flutter/material.dart';
import 'package:stroke_wars/features/canvas/domain/models/stroke.dart';

/// Performance cache for [Paint] objects to avoid reallocation inside draw loops.
class PaintCache {
  final Map<String, Paint> _cache = {};

  /// Resolves or instantiates a cached [Paint] object based on properties.
  Paint getPaint({
    required Color color,
    required double width,
    required double opacity,
  }) {
    final key = '${color.value}_${width}_$opacity';
    return _cache.putIfAbsent(key, () {
      return Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = width
        ..isAntiAlias = true;
    });
  }

  /// Clears paint allocations.
  void clear() => _cache.clear();
}

/// Performance cache for [Path] objects matching [Stroke] coordinates.
class PathCache {
  final Map<String, Path> _cache = {};

  /// Resolves or compiles a cached [Path] for the given stroke.
  Path getPath(Stroke stroke) {
    return _cache.putIfAbsent(stroke.id, () {
      final path = Path();
      if (stroke.points.isEmpty) return path;

      path.moveTo(stroke.points.first.x, stroke.points.first.y);
      for (int i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        path.lineTo(p.x, p.y);
      }
      return path;
    });
  }

  /// Clears path allocations.
  void clear() => _cache.clear();
}

/// Placeholder cache for future custom brush tip textures or shaders.
class BrushCache {
  final Map<String, dynamic> _cache = {};

  /// Resolves value from cache.
  T get<T>(String key, T Function() loader) {
    return _cache.putIfAbsent(key, loader) as T;
  }

  /// Clears brush assets.
  void clear() => _cache.clear();
}
