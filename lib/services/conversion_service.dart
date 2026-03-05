import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/bead_color.dart';
import '../models/conversion_settings.dart';
import '../models/plate_shape.dart';
import '../models/pattern_data.dart';
import '../utils/image_preprocessor.dart';
import '../utils/area_resize.dart';
import '../utils/ciede2000.dart';
import '../utils/color_converter.dart';
import '../utils/floyd_steinberg.dart';
import '../utils/isolated_pixel_remover.dart';
import '../utils/mask_generator.dart';

/// Progress callback: stage name and progress 0.0-1.0
typedef ConversionProgress = void Function(String stage, double progress);

/// Parameters passed to the conversion isolate
class _ConversionParams {
  final List<int> imageBytes;
  final int targetCols;
  final int targetRows;
  final List<Map<String, dynamic>> paletteJson;
  final int ditherModeIndex;
  final double ditherStrength;
  final int maxColors;
  final int shapeIndex;
  final bool removeIsolated;
  final SendPort sendPort;

  _ConversionParams({
    required this.imageBytes,
    required this.targetCols,
    required this.targetRows,
    required this.paletteJson,
    required this.ditherModeIndex,
    required this.ditherStrength,
    required this.maxColors,
    required this.shapeIndex,
    required this.removeIsolated,
    required this.sendPort,
  });
}

/// Result returned from the conversion isolate
class ConversionResult {
  final List<List<String>> grid;
  final Map<String, Map<String, dynamic>> usedColorsJson;

  ConversionResult({required this.grid, required this.usedColorsJson});
}

class ConversionService {
  /// Run the full conversion pipeline in an Isolate.
  static Future<ConversionResult> convert({
    required img.Image croppedImage,
    required ConversionSettings settings,
    required List<BeadColor> palette,
    required bool removeIsolatedPixels,
    ConversionProgress? onProgress,
  }) async {
    final receivePort = ReceivePort();
    final imageBytes = img.encodePng(croppedImage);

    final params = _ConversionParams(
      imageBytes: imageBytes,
      targetCols: settings.size.columns,
      targetRows: settings.size.rows,
      paletteJson: palette.map((c) => c.toJson()).toList(),
      ditherModeIndex: settings.ditherMode.index,
      ditherStrength: settings.ditherStrength,
      maxColors: settings.maxColors,
      shapeIndex: settings.shape.index,
      removeIsolated: removeIsolatedPixels,
      sendPort: receivePort.sendPort,
    );

    final isolate = await Isolate.spawn(_isolateEntry, params);

    ConversionResult? result;

    await for (final message in receivePort) {
      if (message is Map<String, dynamic>) {
        final type = message['type'] as String;
        if (type == 'progress' && onProgress != null) {
          onProgress(
            message['stage'] as String,
            (message['value'] as num).toDouble(),
          );
        } else if (type == 'result') {
          final gridRaw = message['grid'] as List;
          final grid = gridRaw
              .map((row) => (row as List).cast<String>().toList())
              .toList();
          final usedRaw = message['used_colors'] as Map<String, dynamic>;
          result = ConversionResult(
            grid: grid,
            usedColorsJson: usedRaw.cast<String, Map<String, dynamic>>(),
          );
          receivePort.close();
          break;
        } else if (type == 'error') {
          receivePort.close();
          throw Exception(message['message'] as String);
        }
      }
    }

    isolate.kill();

    if (result == null) throw Exception('Conversion failed');
    return result;
  }

  /// Isolate entry point - runs the full pipeline
  static void _isolateEntry(_ConversionParams params) {
    try {
      final sendPort = params.sendPort;
      void sendProgress(String stage, double value) {
        sendPort.send({'type': 'progress', 'stage': stage, 'value': value});
      }

      // Decode image
      final source = img.decodePng(Uint8List.fromList(params.imageBytes))!;
      sendProgress('preprocessing', 0.05);

      // STEP 1: Preprocess
      final preprocessed = ImagePreprocessor.preprocess(source);
      sendProgress('preprocessing', 0.10);

      // STEP 2: Resize using area interpolation
      final resized = AreaResize.resize(
        preprocessed,
        params.targetCols,
        params.targetRows,
      );
      sendProgress('resizing', 0.20);

      // Load palette
      final palette = params.paletteJson
          .map((json) => BeadColor.fromJson(json))
          .toList();

      // Apply shape mask
      final shape = PlateShape.values[params.shapeIndex];
      final mask = MaskGenerator.generate(
        shape,
        params.targetRows,
        params.targetCols,
      );

      // Extract pixel data
      final pixels = List.generate(params.targetRows, (y) {
        return List.generate(params.targetCols, (x) {
          final p = resized.getPixel(x, y);
          return (p.r.toInt(), p.g.toInt(), p.b.toInt());
        });
      });

      // STEP 3: Palette mapping
      List<List<String>> grid;
      final ditherMode = DitherMode.values[params.ditherModeIndex];

      if (ditherMode == DitherMode.floydSteinberg && params.ditherStrength > 0) {
        sendProgress('dithering', 0.30);
        grid = FloydSteinbergDitherer.dither(
          pixels: pixels,
          palette: palette,
          strength: params.ditherStrength,
        );
      } else {
        // Direct mapping using CIEDE2000
        grid = _directMapping(pixels, palette, (progress) {
          sendProgress('mapping', 0.20 + progress * 0.70);
        });
      }

      sendProgress('mapping', 0.85);

      // Apply mask (set masked cells to empty string)
      for (int y = 0; y < params.targetRows; y++) {
        for (int x = 0; x < params.targetCols; x++) {
          if (!mask[y][x]) grid[y][x] = '';
        }
      }

      // STEP 3.5: Color count optimization
      grid = _optimizeColorCount(grid, palette, params.maxColors);
      sendProgress('optimizing', 0.90);

      // STEP 4: Post-processing - isolated pixel removal
      if (params.removeIsolated) {
        grid = IsolatedPixelRemover.removeIsolated(grid);
      }
      sendProgress('finishing', 0.95);

      // Collect used colors
      final usedIds = <String>{};
      for (final row in grid) {
        for (final cell in row) {
          if (cell.isNotEmpty) usedIds.add(cell);
        }
      }
      final usedColors = <String, Map<String, dynamic>>{};
      for (final color in palette) {
        if (usedIds.contains(color.id)) {
          usedColors[color.id] = color.toJson();
        }
      }

      sendProgress('done', 1.0);

      sendPort.send({
        'type': 'result',
        'grid': grid,
        'used_colors': usedColors,
      });
    } catch (e) {
      params.sendPort.send({
        'type': 'error',
        'message': e.toString(),
      });
    }
  }

  /// Direct CIEDE2000 nearest-neighbor mapping
  static List<List<String>> _directMapping(
    List<List<(int, int, int)>> pixels,
    List<BeadColor> palette,
    void Function(double) onProgress,
  ) {
    final rows = pixels.length;
    final cols = pixels[0].length;
    final total = rows * cols;
    int processed = 0;

    return List.generate(rows, (y) {
      return List.generate(cols, (x) {
        final (r, g, b) = pixels[y][x];
        final (labL, labA, labB) = ColorConverter.rgbToLab(r, g, b);

        String bestId = palette[0].id;
        double bestDelta = double.infinity;

        for (final color in palette) {
          final de = Ciede2000.deltaE(
            labL, labA, labB,
            color.labL, color.labA, color.labB,
          );
          if (de < bestDelta) {
            bestDelta = de;
            bestId = color.id;
          }
        }

        processed++;
        if (processed % 100 == 0) {
          onProgress(processed / total);
        }

        return bestId;
      });
    });
  }

  /// Optimize color count: merge least-used colors into nearest used colors.
  static List<List<String>> _optimizeColorCount(
    List<List<String>> grid,
    List<BeadColor> palette,
    int maxColors,
  ) {
    // Count usage
    final counts = <String, int>{};
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isNotEmpty) {
          counts[cell] = (counts[cell] ?? 0) + 1;
        }
      }
    }

    if (counts.length <= maxColors) return grid;

    // Sort by usage (ascending - least used first)
    final sorted = counts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Colors to keep (top N by usage)
    final keepIds = sorted
        .reversed
        .take(maxColors)
        .map((e) => e.key)
        .toSet();

    // Build mapping: removed color → nearest kept color
    final paletteMap = {for (final c in palette) c.id: c};
    final remapTable = <String, String>{};

    for (final entry in sorted) {
      if (keepIds.contains(entry.key)) continue;

      final removed = paletteMap[entry.key];
      if (removed == null) continue;

      String bestId = keepIds.first;
      double bestDelta = double.infinity;

      for (final keepId in keepIds) {
        final kept = paletteMap[keepId];
        if (kept == null) continue;
        final de = Ciede2000.deltaE(
          removed.labL, removed.labA, removed.labB,
          kept.labL, kept.labA, kept.labB,
        );
        if (de < bestDelta) {
          bestDelta = de;
          bestId = keepId;
        }
      }
      remapTable[entry.key] = bestId;
    }

    // Apply remapping
    if (remapTable.isEmpty) return grid;

    return List.generate(grid.length, (y) {
      return List.generate(grid[y].length, (x) {
        final cell = grid[y][x];
        return remapTable[cell] ?? cell;
      });
    });
  }

  /// Re-run just the color optimization (for the "adjust colors" feature).
  /// Faster than full conversion since we skip preprocessing/resize.
  static List<List<String>> reoptimize({
    required List<List<String>> originalGrid,
    required List<BeadColor> palette,
    required int newMaxColors,
    required bool removeIsolated,
  }) {
    var result = _optimizeColorCount(originalGrid, palette, newMaxColors);
    if (removeIsolated) {
      result = IsolatedPixelRemover.removeIsolated(result);
    }
    return result;
  }
}
