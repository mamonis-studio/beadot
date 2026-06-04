import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const text = Color(0xFF111111);
  static const secondary = Color(0xFF888888);
  static const border = Color(0xFFE0E0E0);
  static const emptyCell = Color(0xFFF5F5F5);
  static const gridLine = Color(0xFFE0E0E0);

  // Dark mode
  static const darkBackground = Color(0xFF111111);
  static const darkText = Color(0xFFFFFFFF);
  static const darkEmptyCell = Color(0xFF222222);
  static const darkGridLine = Color(0xFF333333);
}

class AppSizes {
  static const double headerHeight = 48.0;
  static const double captureButtonSize = 72.0;
  static const double galleryThumbSize = 40.0;
  static const double segmentHeight = 36.0;
  static const double plateButtonHeight = 48.0;
  static const double plateButtonSpacing = 8.0;
  static const double paletteBarHeight = 64.0;
  static const double paletteItemSize = 36.0;
  static const double displayModeHeight = 32.0;
  static const double cropConfirmSize = 56.0;
}

class AppStrings {
  static const appName = 'beadot';
  static const bundleId = 'mamonis.studio.beadot';
  static const contactEmail = 'contact@mamonis.studio';
  static const privacyUrl = 'https://beadot.mamonis.studio/privacy_policy.html';
  static const termsUrl = 'https://beadot.mamonis.studio/terms_of_use.html';
  static const supportUrl = 'https://mamonis.studio/contact';
  static const premiumProductId = 'mamonis.studio.beadot.premium';
}

class ConversionDefaults {
  static const int maxColorsBySize15 = 12;
  static const int maxColorsBySize29 = 20;
  static const int maxColorsBySize58 = 35;
  static const int maxColorsBySize128 = 50;
  static const double defaultDitherStrength = 0.5;
  static const double gaussianSigma = 0.5;
  static const double saturationBoost = 1.1;
  static const double histogramClipPercent = 5.0;

  static int defaultMaxColors(int gridSize) {
    if (gridSize <= 15) return maxColorsBySize15;
    if (gridSize <= 29) return maxColorsBySize29;
    if (gridSize <= 58) return maxColorsBySize58;
    return maxColorsBySize128;
  }
}
