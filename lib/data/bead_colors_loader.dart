import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bead_brand.dart';
import '../models/bead_color.dart';
import '../models/conversion_settings.dart';

/// Loads and manages bead color palettes from JSON assets.
class BeadColorsLoader {
  static final Map<BeadBrand, List<BeadColor>> _cache = {};

  /// Load colors for a brand. Cached after first load.
  static Future<List<BeadColor>> loadColors(BeadBrand brand) async {
    if (_cache.containsKey(brand)) return _cache[brand]!;

    final jsonString = await rootBundle.loadString('assets/data/${brand.jsonFileName}');
    final jsonList = jsonDecode(jsonString) as List;
    final colors = jsonList
        .map((e) => BeadColor.fromJson(e as Map<String, dynamic>))
        .where((c) => c.available)
        .toList();

    _cache[brand] = colors;
    return colors;
  }

  /// Get filtered palette based on color filter setting.
  static List<BeadColor> filterPalette(
    List<BeadColor> allColors,
    ColorFilter filter,
  ) {
    switch (filter) {
      case ColorFilter.solidOnly:
        return allColors.where((c) => c.isSolid).toList();
      case ColorFilter.includePearl:
        return allColors.where((c) => c.isSolid || c.isPearl).toList();
      case ColorFilter.all:
        return allColors.where((c) => c.type != 'stripe').toList();
    }
  }

  /// Preload all brands.
  static Future<void> preloadAll() async {
    await Future.wait([
      loadColors(BeadBrand.perler),
      loadColors(BeadBrand.nano),
      loadColors(BeadBrand.hamaMidi),
    ]);
  }
}
