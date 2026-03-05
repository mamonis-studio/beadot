import 'dart:math';

/// CIEDE2000 color difference calculation.
/// Reference: Sharma, Wu, Dalal (2005) - "The CIEDE2000 Color-Difference Formula"
/// Implementation reference: michel-leonard/ciede2000-color-matching (public domain)
///
/// Parameters kL, kC, kH are all 1.0 (standard conditions).
class Ciede2000 {
  static const double _kL = 1.0;
  static const double _kC = 1.0;
  static const double _kH = 1.0;
  static const double _deg2rad = pi / 180.0;
  static const double _rad2deg = 180.0 / pi;
  static const double _pow25to7 = 6103515625.0; // 25^7

  /// Calculate CIEDE2000 color difference (ΔE00) between two Lab colors.
  static double deltaE(
    double l1, double a1, double b1,
    double l2, double a2, double b2,
  ) {
    // Step 1: Calculate C'ab, h'ab
    final c1 = sqrt(a1 * a1 + b1 * b1);
    final c2 = sqrt(a2 * a2 + b2 * b2);
    final cAvg = (c1 + c2) / 2.0;

    final cAvg7 = pow(cAvg, 7).toDouble();
    final g = 0.5 * (1.0 - sqrt(cAvg7 / (cAvg7 + _pow25to7)));

    final a1p = a1 * (1.0 + g);
    final a2p = a2 * (1.0 + g);

    final c1p = sqrt(a1p * a1p + b1 * b1);
    final c2p = sqrt(a2p * a2p + b2 * b2);

    double h1p = _atan2Deg(b1, a1p);
    double h2p = _atan2Deg(b2, a2p);

    // Step 2: Calculate ΔL', ΔC', ΔH'
    final dLp = l2 - l1;
    final dCp = c2p - c1p;

    double dhp;
    if (c1p * c2p == 0.0) {
      dhp = 0.0;
    } else if ((h2p - h1p).abs() <= 180.0) {
      dhp = h2p - h1p;
    } else if (h2p - h1p > 180.0) {
      dhp = h2p - h1p - 360.0;
    } else {
      dhp = h2p - h1p + 360.0;
    }

    final dHp = 2.0 * sqrt(c1p * c2p) * sin(dhp / 2.0 * _deg2rad);

    // Step 3: Calculate CIEDE2000 ΔE00
    final lAvgP = (l1 + l2) / 2.0;
    final cAvgP = (c1p + c2p) / 2.0;

    double hAvgP;
    if (c1p * c2p == 0.0) {
      hAvgP = h1p + h2p;
    } else if ((h1p - h2p).abs() <= 180.0) {
      hAvgP = (h1p + h2p) / 2.0;
    } else if (h1p + h2p < 360.0) {
      hAvgP = (h1p + h2p + 360.0) / 2.0;
    } else {
      hAvgP = (h1p + h2p - 360.0) / 2.0;
    }

    final t = 1.0 -
        0.17 * cos((hAvgP - 30.0) * _deg2rad) +
        0.24 * cos(2.0 * hAvgP * _deg2rad) +
        0.32 * cos((3.0 * hAvgP + 6.0) * _deg2rad) -
        0.20 * cos((4.0 * hAvgP - 63.0) * _deg2rad);

    final lAvgPm50sq = (lAvgP - 50.0) * (lAvgP - 50.0);
    final sL = 1.0 + 0.015 * lAvgPm50sq / sqrt(20.0 + lAvgPm50sq);
    final sC = 1.0 + 0.045 * cAvgP;
    final sH = 1.0 + 0.015 * cAvgP * t;

    final cAvgP7 = pow(cAvgP, 7).toDouble();
    final rC = 2.0 * sqrt(cAvgP7 / (cAvgP7 + _pow25to7));

    final dTheta = 30.0 * exp(-((hAvgP - 275.0) / 25.0) * ((hAvgP - 275.0) / 25.0));
    final rT = -sin(2.0 * dTheta * _deg2rad) * rC;

    final lpTerm = dLp / (_kL * sL);
    final cpTerm = dCp / (_kC * sC);
    final hpTerm = dHp / (_kH * sH);

    return sqrt(
      lpTerm * lpTerm +
          cpTerm * cpTerm +
          hpTerm * hpTerm +
          rT * cpTerm * hpTerm,
    );
  }

  static double _atan2Deg(double y, double x) {
    final h = atan2(y, x) * _rad2deg;
    return h < 0 ? h + 360.0 : h;
  }
}
