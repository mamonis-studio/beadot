enum PlateShape {
  square,
  hexagon,
  circle,
  heart,
  star;

  String get displayNameJa {
    switch (this) {
      case PlateShape.square:
        return '四角形';
      case PlateShape.hexagon:
        return '六角形';
      case PlateShape.circle:
        return '丸形';
      case PlateShape.heart:
        return 'ハート形';
      case PlateShape.star:
        return '星形';
    }
  }

  String get displayNameEn {
    switch (this) {
      case PlateShape.square:
        return 'Square';
      case PlateShape.hexagon:
        return 'Hexagon';
      case PlateShape.circle:
        return 'Circle';
      case PlateShape.heart:
        return 'Heart';
      case PlateShape.star:
        return 'Star';
    }
  }

  String get displayNameZh {
    switch (this) {
      case PlateShape.square:
        return '正方形';
      case PlateShape.hexagon:
        return '六角形';
      case PlateShape.circle:
        return '圆形';
      case PlateShape.heart:
        return '心形';
      case PlateShape.star:
        return '星形';
    }
  }

  String get iconChar {
    switch (this) {
      case PlateShape.square:
        return '■';
      case PlateShape.hexagon:
        return '⬡';
      case PlateShape.circle:
        return '●';
      case PlateShape.heart:
        return '♥';
      case PlateShape.star:
        return '★';
    }
  }

  /// Whether this shape uses offset (staggered) grid
  bool get isHexGrid => this == PlateShape.hexagon;

  /// Whether this shape uses a mask on a square grid
  bool get usesMask {
    switch (this) {
      case PlateShape.circle:
      case PlateShape.heart:
      case PlateShape.star:
        return true;
      default:
        return false;
    }
  }

  /// Crop aspect ratio for this shape (width:height)
  double get cropAspectRatio {
    switch (this) {
      case PlateShape.square:
      case PlateShape.hexagon:
      case PlateShape.circle:
      case PlateShape.heart:
      case PlateShape.star:
        return 1.0;
    }
  }
}
