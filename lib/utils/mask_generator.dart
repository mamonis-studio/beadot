import 'dart:math';
import '../models/plate_shape.dart';

/// Generates boolean masks for non-rectangular plate shapes.
/// true = active cell (bead placed), false = masked out (empty).
class MaskGenerator {
  /// Generate a mask for the given shape and grid dimensions.
  /// Returns 2D array [rows][cols] of booleans.
  static List<List<bool>> generate(PlateShape shape, int rows, int cols) {
    switch (shape) {
      case PlateShape.square:
      case PlateShape.hexagon:
        // Full grid, no masking
        return List.generate(rows, (_) => List.filled(cols, true));
      case PlateShape.circle:
        return _circleMask(rows, cols);
      case PlateShape.heart:
        return _heartMask(rows, cols);
      case PlateShape.star:
        return _starMask(rows, cols);
    }
  }

  /// Count active cells in a mask
  static int activeCount(List<List<bool>> mask) {
    int count = 0;
    for (final row in mask) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }

  /// Circle mask: inscribed circle within the grid
  static List<List<bool>> _circleMask(int rows, int cols) {
    final centerY = (rows - 1) / 2.0;
    final centerX = (cols - 1) / 2.0;
    final radius = min(rows, cols) / 2.0;

    return List.generate(rows, (y) {
      return List.generate(cols, (x) {
        final dx = x - centerX;
        final dy = y - centerY;
        return dx * dx + dy * dy <= radius * radius;
      });
    });
  }

  /// Heart mask using parametric heart curve
  static List<List<bool>> _heartMask(int rows, int cols) {
    final mask = List.generate(rows, (_) => List.filled(cols, false));
    final centerX = (cols - 1) / 2.0;
    final centerY = (rows - 1) / 2.0;
    final scale = min(rows, cols) / 2.0;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        // Normalize to [-1, 1] range, flip Y axis
        final nx = (x - centerX) / scale;
        final ny = -(y - centerY) / scale + 0.2; // shift up slightly

        // Heart curve: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
        final x2 = nx * nx;
        final y2 = ny * ny;
        final val = (x2 + y2 - 1);
        mask[y][x] = val * val * val - x2 * ny * ny * ny <= 0;
      }
    }
    return mask;
  }

  /// Star mask (5-pointed star)
  static List<List<bool>> _starMask(int rows, int cols) {
    final mask = List.generate(rows, (_) => List.filled(cols, false));
    final centerX = (cols - 1) / 2.0;
    final centerY = (rows - 1) / 2.0;
    final outerRadius = min(rows, cols) / 2.0;
    final innerRadius = outerRadius * 0.38; // Golden ratio-ish

    // Generate star polygon vertices
    final points = <(double, double)>[];
    for (int i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5; // Start from top
      final r = i.isEven ? outerRadius : innerRadius;
      points.add((centerX + r * cos(angle), centerY + r * sin(angle)));
    }

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        mask[y][x] = _pointInPolygon(x.toDouble(), y.toDouble(), points);
      }
    }
    return mask;
  }

  /// Ray casting algorithm for point-in-polygon test
  static bool _pointInPolygon(double px, double py, List<(double, double)> polygon) {
    bool inside = false;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final (xi, yi) = polygon[i];
      final (xj, yj) = polygon[j];
      if (((yi > py) != (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }
}
