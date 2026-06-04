import 'dart:ui';

class BeadColor {
  final String id;
  final String brand;
  final String nameJa;
  final String nameEn;
  final String nameZh;
  final String hex;
  final int r;
  final int g;
  final int b;
  final double labL;
  final double labA;
  final double labB;
  final String type; // solid, pearl, neon, glow, stripe
  final String symbol;
  final bool available;

  const BeadColor({
    required this.id,
    required this.brand,
    required this.nameJa,
    required this.nameEn,
    required this.nameZh,
    required this.hex,
    required this.r,
    required this.g,
    required this.b,
    required this.labL,
    required this.labA,
    required this.labB,
    required this.type,
    required this.symbol,
    this.available = true,
  });

  factory BeadColor.fromJson(Map<String, dynamic> json) {
    return BeadColor(
      id: json['id'] as String,
      brand: json['brand'] as String,
      nameJa: json['name_ja'] as String,
      nameEn: json['name_en'] as String,
      nameZh: json['name_zh'] as String,
      hex: json['hex'] as String,
      r: json['r'] as int,
      g: json['g'] as int,
      b: json['b'] as int,
      labL: (json['lab_l'] as num).toDouble(),
      labA: (json['lab_a'] as num).toDouble(),
      labB: (json['lab_b'] as num).toDouble(),
      type: json['type'] as String,
      symbol: json['symbol'] as String,
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'name_ja': nameJa,
        'name_en': nameEn,
        'name_zh': nameZh,
        'hex': hex,
        'r': r,
        'g': g,
        'b': b,
        'lab_l': labL,
        'lab_a': labA,
        'lab_b': labB,
        'type': type,
        'symbol': symbol,
        'available': available,
      };

  Color get color => Color.fromARGB(255, r, g, b);

  bool get isSolid => type == 'solid';
  bool get isPearl => type == 'pearl';
  bool get isNeon => type == 'neon';
  bool get isSpecial => !isSolid;

  /// Luminance for deciding text color (dark text on light bg, white text on dark bg)
  double get luminance => (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

  /// Text color for overlay on this bead color
  Color get contrastTextColor => luminance > 0.5 ? const Color(0xFF111111) : const Color(0xFFFFFFFF);

  String localizedName(String locale) {
    switch (locale) {
      case 'ja':
        return nameJa;
      case 'zh':
        return nameZh;
      default:
        return nameEn;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BeadColor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BeadColor($id: $nameEn)';
}
