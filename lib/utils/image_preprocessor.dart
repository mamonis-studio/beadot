import 'dart:math';
import 'package:image/image.dart' as img;

/// Image preprocessing pipeline.
/// Applied before resizing to improve conversion quality.
class ImagePreprocessor {
  /// Apply full preprocessing pipeline.
  static img.Image preprocess(img.Image source) {
    var result = source;
    result = applyGaussianBlur(result, sigma: 0.5);
    result = applyHistogramStretch(result, clipPercent: 5.0);
    result = applySaturationBoost(result, factor: 1.1);
    return result;
  }

  /// Gaussian blur for noise reduction.
  /// σ=0.5 is very light - just enough to smooth sensor noise
  /// without losing image detail.
  static img.Image applyGaussianBlur(img.Image source, {double sigma = 0.5}) {
    final radius = (sigma * 3).ceil();
    if (radius < 1) return source;

    // Generate 1D kernel
    final size = radius * 2 + 1;
    final kernel = List<double>.filled(size, 0);
    double sum = 0;
    for (int i = 0; i < size; i++) {
      final x = i - radius;
      kernel[i] = exp(-(x * x) / (2 * sigma * sigma));
      sum += kernel[i];
    }
    // Normalize
    for (int i = 0; i < size; i++) {
      kernel[i] /= sum;
    }

    final w = source.width;
    final h = source.height;

    // Horizontal pass
    var temp = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double rr = 0, gg = 0, bb = 0;
        for (int k = -radius; k <= radius; k++) {
          final sx = (x + k).clamp(0, w - 1);
          final pixel = source.getPixel(sx, y);
          final weight = kernel[k + radius];
          rr += pixel.r * weight;
          gg += pixel.g * weight;
          bb += pixel.b * weight;
        }
        temp.setPixelRgb(x, y, rr.round().clamp(0, 255), gg.round().clamp(0, 255), bb.round().clamp(0, 255));
      }
    }

    // Vertical pass
    var result = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double rr = 0, gg = 0, bb = 0;
        for (int k = -radius; k <= radius; k++) {
          final sy = (y + k).clamp(0, h - 1);
          final pixel = temp.getPixel(x, sy);
          final weight = kernel[k + radius];
          rr += pixel.r * weight;
          gg += pixel.g * weight;
          bb += pixel.b * weight;
        }
        result.setPixelRgb(x, y, rr.round().clamp(0, 255), gg.round().clamp(0, 255), bb.round().clamp(0, 255));
      }
    }

    return result;
  }

  /// Histogram stretching (contrast auto-adjustment).
  /// Clips top and bottom [clipPercent]% of histogram, then stretches to full range.
  static img.Image applyHistogramStretch(img.Image source, {double clipPercent = 5.0}) {
    final w = source.width;
    final h = source.height;
    final totalPixels = w * h;
    final clipCount = (totalPixels * clipPercent / 100.0).round();

    // Build luminance histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = source.getPixel(x, y);
        final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
        histogram[lum]++;
      }
    }

    // Find clip points
    int lowClip = 0, highClip = 255;
    int cumLow = 0;
    for (int i = 0; i < 256; i++) {
      cumLow += histogram[i];
      if (cumLow >= clipCount) {
        lowClip = i;
        break;
      }
    }
    int cumHigh = 0;
    for (int i = 255; i >= 0; i--) {
      cumHigh += histogram[i];
      if (cumHigh >= clipCount) {
        highClip = i;
        break;
      }
    }

    if (highClip <= lowClip) return source;
    final range = (highClip - lowClip).toDouble();

    final result = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = source.getPixel(x, y);
        final r = ((p.r - lowClip) / range * 255).round().clamp(0, 255);
        final g = ((p.g - lowClip) / range * 255).round().clamp(0, 255);
        final b = ((p.b - lowClip) / range * 255).round().clamp(0, 255);
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  /// Saturation boost in HSL space.
  /// factor=1.1 means +10% saturation.
  static img.Image applySaturationBoost(img.Image source, {double factor = 1.1}) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = source.getPixel(x, y);
        final r = p.r / 255.0;
        final g = p.g / 255.0;
        final b = p.b / 255.0;

        final maxC = max(r, max(g, b));
        final minC = min(r, min(g, b));
        final delta = maxC - minC;
        final l = (maxC + minC) / 2.0;

        if (delta == 0) {
          result.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
          continue;
        }

        double h2;
        if (maxC == r) {
          h2 = ((g - b) / delta) % 6;
        } else if (maxC == g) {
          h2 = (b - r) / delta + 2;
        } else {
          h2 = (r - g) / delta + 4;
        }
        h2 *= 60;
        if (h2 < 0) h2 += 360;

        double s = delta / (1 - (2 * l - 1).abs());
        s = (s * factor).clamp(0.0, 1.0);

        // HSL back to RGB
        final c = (1 - (2 * l - 1).abs()) * s;
        final x2 = c * (1 - ((h2 / 60) % 2 - 1).abs());
        final m = l - c / 2;

        double r1, g1, b1;
        if (h2 < 60) {
          r1 = c; g1 = x2; b1 = 0;
        } else if (h2 < 120) {
          r1 = x2; g1 = c; b1 = 0;
        } else if (h2 < 180) {
          r1 = 0; g1 = c; b1 = x2;
        } else if (h2 < 240) {
          r1 = 0; g1 = x2; b1 = c;
        } else if (h2 < 300) {
          r1 = x2; g1 = 0; b1 = c;
        } else {
          r1 = c; g1 = 0; b1 = x2;
        }

        result.setPixelRgb(
          x, y,
          ((r1 + m) * 255).round().clamp(0, 255),
          ((g1 + m) * 255).round().clamp(0, 255),
          ((b1 + m) * 255).round().clamp(0, 255),
        );
      }
    }
    return result;
  }
}
