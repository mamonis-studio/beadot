/// Removes isolated pixels from a bead pattern.
/// An isolated pixel is one where none of its 8 neighbors share the same color.
/// It gets replaced by the most frequent neighbor color.
class IsolatedPixelRemover {
  /// Remove isolated pixels from the grid.
  /// [grid] is modified in place and also returned.
  static List<List<String>> removeIsolated(List<List<String>> grid) {
    final rows = grid.length;
    if (rows == 0) return grid;
    final cols = grid[0].length;

    // Work on a copy to avoid cascading changes
    final original = List.generate(rows, (y) => List<String>.from(grid[y]));
    final result = List.generate(rows, (y) => List<String>.from(grid[y]));

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final current = original[y][x];
        if (current.isEmpty) continue; // Masked out cell

        // Count neighbors with same color
        final neighborCounts = <String, int>{};
        bool hasSameNeighbor = false;

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final ny = y + dy;
            final nx = x + dx;
            if (ny < 0 || ny >= rows || nx < 0 || nx >= cols) continue;
            final neighbor = original[ny][nx];
            if (neighbor.isEmpty) continue;

            if (neighbor == current) {
              hasSameNeighbor = true;
            }
            neighborCounts[neighbor] = (neighborCounts[neighbor] ?? 0) + 1;
          }
        }

        // If no neighbor shares this color, replace with most frequent neighbor
        if (!hasSameNeighbor && neighborCounts.isNotEmpty) {
          String bestColor = current;
          int bestCount = 0;
          for (final entry in neighborCounts.entries) {
            if (entry.value > bestCount) {
              bestCount = entry.value;
              bestColor = entry.key;
            }
          }
          result[y][x] = bestColor;
        }
      }
    }

    return result;
  }
}
