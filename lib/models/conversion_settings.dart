import 'bead_brand.dart';
import 'plate_shape.dart';
import 'plate_size.dart';

enum DitherMode { direct, floydSteinberg }

enum ColorFilter { solidOnly, includePearl, all }

class ConversionSettings {
  final BeadBrand brand;
  final PlateShape shape;
  final PlateSize size;
  final DitherMode ditherMode;
  final double ditherStrength; // 0.0 ~ 1.0
  final int maxColors;
  final ColorFilter colorFilter;

  const ConversionSettings({
    this.brand = BeadBrand.perler,
    this.shape = PlateShape.square,
    this.size = PlateSize.s,
    this.ditherMode = DitherMode.direct,
    this.ditherStrength = 0.5,
    this.maxColors = 12,
    this.colorFilter = ColorFilter.solidOnly,
  });

  ConversionSettings copyWith({
    BeadBrand? brand,
    PlateShape? shape,
    PlateSize? size,
    DitherMode? ditherMode,
    double? ditherStrength,
    int? maxColors,
    ColorFilter? colorFilter,
  }) {
    return ConversionSettings(
      brand: brand ?? this.brand,
      shape: shape ?? this.shape,
      size: size ?? this.size,
      ditherMode: ditherMode ?? this.ditherMode,
      ditherStrength: ditherStrength ?? this.ditherStrength,
      maxColors: maxColors ?? this.maxColors,
      colorFilter: colorFilter ?? this.colorFilter,
    );
  }

  /// Summary string for display in crop screen
  String get summaryText {
    final brandName = brand.displayNameEn.toUpperCase();
    final shapeName = shape.displayNameEn;
    final sizeLabel = size.label;
    final dither = ditherMode == DitherMode.floydSteinberg ? 'DITHER' : 'DIRECT';
    return '$brandName / $shapeName $sizeLabel / ${size.displaySize} / $dither';
  }

  Map<String, dynamic> toJson() => {
        'brand': brand.index,
        'shape': shape.index,
        'size_cols': size.columns,
        'size_rows': size.rows,
        'size_label': size.label,
        'size_premium': size.isPremium,
        'dither_mode': ditherMode.index,
        'dither_strength': ditherStrength,
        'max_colors': maxColors,
        'color_filter': colorFilter.index,
      };

  factory ConversionSettings.fromJson(Map<String, dynamic> json) {
    return ConversionSettings(
      brand: BeadBrand.values[json['brand'] as int],
      shape: PlateShape.values[json['shape'] as int],
      size: PlateSize(
        label: json['size_label'] as String,
        columns: json['size_cols'] as int,
        rows: json['size_rows'] as int,
        isPremium: json['size_premium'] as bool? ?? false,
      ),
      ditherMode: DitherMode.values[json['dither_mode'] as int],
      ditherStrength: (json['dither_strength'] as num).toDouble(),
      maxColors: json['max_colors'] as int,
      colorFilter: ColorFilter.values[json['color_filter'] as int],
    );
  }
}
