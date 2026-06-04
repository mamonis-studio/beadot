import 'dart:math';

/// Color space conversion utilities.
/// RGB → sRGB linear → XYZ (D65) → Lab
class ColorConverter {
  // D65 white point
  static const double _xn = 0.95047;
  static const double _yn = 1.00000;
  static const double _zn = 1.08883;

  /// Convert sRGB (0-255) to CIE Lab.
  static (double L, double a, double b) rgbToLab(int r, int g, int bVal) {
    // sRGB to linear
    final rl = _srgbToLinear(r / 255.0);
    final gl = _srgbToLinear(g / 255.0);
    final bl = _srgbToLinear(bVal / 255.0);

    // Linear RGB to XYZ (D65)
    final x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375;
    final y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750;
    final z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041;

    // XYZ to Lab
    final fx = _labF(x / _xn);
    final fy = _labF(y / _yn);
    final fz = _labF(z / _zn);

    final labL = 116.0 * fy - 16.0;
    final labA = 500.0 * (fx - fy);
    final labB = 200.0 * (fy - fz);

    return (labL, labA, labB);
  }

  /// Convert CIE Lab to sRGB (0-255), clamped.
  static (int r, int g, int b) labToRgb(double labL, double labA, double labB) {
    // Lab to XYZ
    final fy = (labL + 16.0) / 116.0;
    final fx = labA / 500.0 + fy;
    final fz = fy - labB / 200.0;

    final x = _xn * _labFInv(fx);
    final y = _yn * _labFInv(fy);
    final z = _zn * _labFInv(fz);

    // XYZ to linear RGB
    final rl = x * 3.2404542 + y * -1.5371385 + z * -0.4985314;
    final gl = x * -0.9692660 + y * 1.8760108 + z * 0.0415560;
    final bl = x * 0.0556434 + y * -0.2040259 + z * 1.0572252;

    // Linear to sRGB
    final r = (_linearToSrgb(rl) * 255.0).round().clamp(0, 255);
    final g = (_linearToSrgb(gl) * 255.0).round().clamp(0, 255);
    final b = (_linearToSrgb(bl) * 255.0).round().clamp(0, 255);

    return (r, g, b);
  }

  static double _srgbToLinear(double c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _linearToSrgb(double c) {
    return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
  }

  static double _labF(double t) {
    return t > 0.008856 ? pow(t, 1.0 / 3.0).toDouble() : (903.3 * t + 16.0) / 116.0;
  }

  static double _labFInv(double t) {
    return t > 0.206893 ? t * t * t : (116.0 * t - 16.0) / 903.3;
  }
}
