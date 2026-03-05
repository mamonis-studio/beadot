import '../models/bead_color.dart';
import 'ciede2000.dart';
import 'color_converter.dart';

/// Floyd-Steinberg error diffusion dithering in Lab color space.
///
/// Instead of processing RGB channels independently (which causes color bleeding),
/// this implementation works in Lab space where error vectors represent
/// perceptual color differences.
class FloydSteinbergDitherer {
  /// Apply Floyd-Steinberg dithering to a pixel grid.
  ///
  /// [pixels] - 2D array of RGB pixels as (r, g, b) tuples
  /// [palette] - Available bead colors to map to
  /// [strength] - Dithering strength 0.0 (=direct mapping) to 1.0 (=full FS)
  ///
  /// Returns 2D array of BeadColor IDs
  static List<List<String>> dither({
    required List<List<(int r, int g, int b)>> pixels,
    required List<BeadColor> palette,
    required double strength,
  }) {
    final rows = pixels.length;
    final cols = pixels[0].length;

    // Convert pixel grid to Lab space (mutable working copy)
    final labGrid = List.generate(rows, (y) {
      return List.generate(cols, (x) {
        final (r, g, b) = pixels[y][x];
        final (labL, labA, labB) = ColorConverter.rgbToLab(r, g, b);
        return [labL, labA, labB]; // mutable
      });
    });

    // Result grid
    final result = List.generate(rows, (_) => List.filled(cols, ''));

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final currentLab = labGrid[y][x];
        final currentL = currentLab[0];
        final currentA = currentLab[1];
        final currentB = currentLab[2];

        // Find nearest palette color using CIEDE2000
        String bestId = palette[0].id;
        double bestDelta = double.infinity;

        for (final color in palette) {
          final de = Ciede2000.deltaE(
            currentL, currentA, currentB,
            color.labL, color.labA, color.labB,
          );
          if (de < bestDelta) {
            bestDelta = de;
            bestId = color.id;
          }
        }

        result[y][x] = bestId;

        // Calculate quantization error in Lab space
        final matched = palette.firstWhere((c) => c.id == bestId);
        final errL = (currentL - matched.labL) * strength;
        final errA = (currentA - matched.labA) * strength;
        final errB = (currentB - matched.labB) * strength;

        // Distribute error to neighbors (Floyd-Steinberg coefficients)
        // Right:      7/16
        // Bottom-left: 3/16
        // Bottom:     5/16
        // Bottom-right: 1/16
        _addError(labGrid, x + 1, y, cols, rows, errL, errA, errB, 7.0 / 16.0);
        _addError(labGrid, x - 1, y + 1, cols, rows, errL, errA, errB, 3.0 / 16.0);
        _addError(labGrid, x, y + 1, cols, rows, errL, errA, errB, 5.0 / 16.0);
        _addError(labGrid, x + 1, y + 1, cols, rows, errL, errA, errB, 1.0 / 16.0);
      }
    }

    return result;
  }

  static void _addError(
    List<List<List<double>>> grid,
    int x, int y,
    int cols, int rows,
    double errL, double errA, double errB,
    double factor,
  ) {
    if (x < 0 || x >= cols || y < 0 || y >= rows) return;
    grid[y][x][0] += errL * factor;
    grid[y][x][1] += errA * factor;
    grid[y][x][2] += errB * factor;
  }
}
