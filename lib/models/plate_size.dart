class PlateSize {
  final String label;
  final int columns;
  final int rows;
  final bool isPremium;

  const PlateSize({
    required this.label,
    required this.columns,
    required this.rows,
    this.isPremium = false,
  });

  int get totalCells => columns * rows;

  double get aspectRatio => columns / rows;

  bool get isSquare => columns == rows;

  String get displaySize => '${columns}×$rows';

  @override
  String toString() => '$label — $displaySize';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlateSize &&
          runtimeType == other.runtimeType &&
          columns == other.columns &&
          rows == other.rows;

  @override
  int get hashCode => columns.hashCode ^ rows.hashCode;

  // Predefined sizes
  static const s = PlateSize(label: 'S', columns: 15, rows: 15);
  static const l = PlateSize(label: 'L', columns: 29, rows: 29);
  static const twoL = PlateSize(label: '2L', columns: 29, rows: 58, isPremium: true);
  static const fourL = PlateSize(label: '4L', columns: 58, rows: 58, isPremium: true);

  static PlateSize custom(int columns, int rows) => PlateSize(
        label: 'CUSTOM',
        columns: columns.clamp(8, 128),
        rows: rows.clamp(8, 128),
        isPremium: true,
      );

  static const squareSizes = [s, l, twoL, fourL];
  static const hexSizes = [s, l];
  static const circleSizes = [s];
  static const starSizes = [s];
  static const heartSizes = [s, l];
}
