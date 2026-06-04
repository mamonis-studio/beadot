import 'dart:math';
import 'package:image/image.dart' as img;

/// Area interpolation resize (equivalent to OpenCV INTER_AREA).
/// Best for downscaling: averages pixel areas for minimal information loss.
/// Bead patterns are always downscaled, so Area interpolation is ideal.
class AreaResize {
  /// sRGB (0..255) -> linear-light (0..1) lookup table.
  static final List<double> _srgbToLinear = List.generate(256, (i) {
    final c = i / 255.0;
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  });

  /// Linear-light (0..1) -> sRGB (0..255).
  static int _linearToSrgb(double l) {
    final v = l.clamp(0.0, 1.0).toDouble();
    final s = v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055;
    return (s * 255.0).round().clamp(0, 255).toInt();
  }

  /// Resize image to target dimensions using area interpolation.
  static img.Image resize(img.Image source, int targetWidth, int targetHeight) {
    final srcW = source.width;
    final srcH = source.height;

    if (targetWidth >= srcW && targetHeight >= srcH) {
      // Upscaling: fall back to bilinear (shouldn't happen for bead patterns)
      return img.copyResize(source, width: targetWidth, height: targetHeight,
          interpolation: img.Interpolation.linear);
    }

    final result = img.Image(width: targetWidth, height: targetHeight);

    final scaleX = srcW / targetWidth;
    final scaleY = srcH / targetHeight;

    for (int ty = 0; ty < targetHeight; ty++) {
      for (int tx = 0; tx < targetWidth; tx++) {
        // Source region for this target pixel
        final srcX0 = tx * scaleX;
        final srcY0 = ty * scaleY;
        final srcX1 = (tx + 1) * scaleX;
        final srcY1 = (ty + 1) * scaleY;

        double rSum = 0, gSum = 0, bSum = 0;
        double areaSum = 0;

        final ixStart = srcX0.floor();
        final ixEnd = srcX1.ceil().clamp(0, srcW);
        final iyStart = srcY0.floor();
        final iyEnd = srcY1.ceil().clamp(0, srcH);

        for (int iy = iyStart; iy < iyEnd; iy++) {
          for (int ix = ixStart; ix < ixEnd; ix++) {
            // Calculate overlap area
            final overlapX0 = ix < srcX0 ? srcX0 : ix.toDouble();
            final overlapX1 = (ix + 1) > srcX1 ? srcX1 : (ix + 1).toDouble();
            final overlapY0 = iy < srcY0 ? srcY0 : iy.toDouble();
            final overlapY1 = (iy + 1) > srcY1 ? srcY1 : (iy + 1).toDouble();

            if (overlapX1 <= overlapX0 || overlapY1 <= overlapY0) continue;

            final area = (overlapX1 - overlapX0) * (overlapY1 - overlapY0);
            final pixel = source.getPixel(ix.clamp(0, srcW - 1), iy.clamp(0, srcH - 1));

            rSum += _srgbToLinear[pixel.r.toInt()] * area;
            gSum += _srgbToLinear[pixel.g.toInt()] * area;
            bSum += _srgbToLinear[pixel.b.toInt()] * area;
            areaSum += area;
          }
        }

        if (areaSum > 0) {
          result.setPixelRgb(
            tx, ty,
            _linearToSrgb(rSum / areaSum),
            _linearToSrgb(gSum / areaSum),
            _linearToSrgb(bSum / areaSum),
          );
        }
      }
    }

    return result;
  }
}
