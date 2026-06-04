enum BeadBrand {
  perler,
  nano,
  hamaMidi,
  hamaMini;

  String get displayName {
    switch (this) {
      case BeadBrand.perler:
        return 'パーラー';
      case BeadBrand.nano:
        return 'ナノ';
      case BeadBrand.hamaMidi:
        return 'ハマ ミディ';
      case BeadBrand.hamaMini:
        return 'ハマ ミニ';
    }
  }

  String get displayNameEn {
    switch (this) {
      case BeadBrand.perler:
        return 'Perler';
      case BeadBrand.nano:
        return 'Nano';
      case BeadBrand.hamaMidi:
        return 'Hama Midi';
      case BeadBrand.hamaMini:
        return 'Hama Mini';
    }
  }

  String get displayNameZh {
    switch (this) {
      case BeadBrand.perler:
        return '拼豆';
      case BeadBrand.nano:
        return '迷你拼豆';
      case BeadBrand.hamaMidi:
        return '哈马中号';
      case BeadBrand.hamaMini:
        return '哈马迷你';
    }
  }

  String get jsonFileName {
    switch (this) {
      case BeadBrand.perler:
        return 'perler_colors.json';
      case BeadBrand.nano:
        return 'nano_colors.json';
      case BeadBrand.hamaMidi:
      case BeadBrand.hamaMini:
        return 'hama_colors.json';
    }
  }

  /// Bead diameter in mm
  double get beadDiameterMm {
    switch (this) {
      case BeadBrand.perler:
        return 5.0;
      case BeadBrand.nano:
        return 2.6;
      case BeadBrand.hamaMidi:
        return 5.0;
      case BeadBrand.hamaMini:
        return 2.5;
    }
  }

  /// Whether special plate shapes (hex, circle, heart, star) are supported
  bool get supportsSpecialShapes => this == BeadBrand.perler;
}
