import 'dart:convert';
import 'bead_color.dart';
import 'conversion_settings.dart';

class PatternData {
  final int? dbId;
  final DateTime createdAt;
  final ConversionSettings settings;

  /// 2D grid of bead color IDs. grid[row][col] = colorId
  final List<List<String>> grid;

  /// Map of colorId -> BeadColor used in this pattern
  final Map<String, BeadColor> usedColors;

  /// Original photo path (in app documents dir)
  final String originalPhotoPath;

  /// Optional title set by user
  final String? title;

  const PatternData({
    this.dbId,
    required this.createdAt,
    required this.settings,
    required this.grid,
    required this.usedColors,
    required this.originalPhotoPath,
    this.title,
  });

  int get rows => grid.length;
  int get columns => grid.isEmpty ? 0 : grid[0].length;
  int get totalBeads => _countBeads();

  int _countBeads() {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isNotEmpty) count++;
      }
    }
    return count;
  }

  /// Count beads per color, sorted by count descending
  List<MapEntry<BeadColor, int>> get beadCounts {
    final counts = <String, int>{};
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isNotEmpty) {
          counts[cell] = (counts[cell] ?? 0) + 1;
        }
      }
    }
    final entries = counts.entries
        .where((e) => usedColors.containsKey(e.key))
        .map((e) => MapEntry(usedColors[e.key]!, e.value))
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  int get usedColorCount => usedColors.length;

  /// Check if a cell is active (not masked out)
  bool isCellActive(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) return false;
    return grid[row][col].isNotEmpty;
  }

  BeadColor? colorAt(int row, int col) {
    if (!isCellActive(row, col)) return null;
    return usedColors[grid[row][col]];
  }

  Map<String, dynamic> toDbMap() => {
        'created_at': createdAt.toIso8601String(),
        'settings_json': jsonEncode(settings.toJson()),
        'grid_json': jsonEncode(grid),
        'used_colors_json': jsonEncode(
          usedColors.map((k, v) => MapEntry(k, v.toJson())),
        ),
        'original_photo_path': originalPhotoPath,
        'title': title,
      };

  factory PatternData.fromDbMap(Map<String, dynamic> map) {
    final gridRaw = jsonDecode(map['grid_json'] as String) as List;
    final grid = gridRaw
        .map((row) => (row as List).map((cell) => cell as String).toList())
        .toList();

    final colorsRaw =
        jsonDecode(map['used_colors_json'] as String) as Map<String, dynamic>;
    final usedColors = colorsRaw.map(
      (k, v) => MapEntry(k, BeadColor.fromJson(v as Map<String, dynamic>)),
    );

    return PatternData(
      dbId: map['id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      settings: ConversionSettings.fromJson(
        jsonDecode(map['settings_json'] as String) as Map<String, dynamic>,
      ),
      grid: grid,
      usedColors: usedColors,
      originalPhotoPath: map['original_photo_path'] as String,
      title: map['title'] as String?,
    );
  }
}
