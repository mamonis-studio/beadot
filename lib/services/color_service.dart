import '../models/bead_color.dart';
import '../utils/ciede2000.dart';

/// Color matching and palette utility service.
class ColorService {
  /// Find the nearest bead color using CIEDE2000.
  static BeadColor findNearest(
    double labL, double labA, double labB,
    List<BeadColor> palette,
  ) {
    BeadColor best = palette.first;
    double bestDelta = double.infinity;

    for (final color in palette) {
      final de = Ciede2000.deltaE(
        labL, labA, labB,
        color.labL, color.labA, color.labB,
      );
      if (de < bestDelta) {
        bestDelta = de;
        best = color;
      }
    }
    return best;
  }

  /// Select top N most representative colors from a list of used colors.
  /// Uses a greedy maximin approach for palette diversity.
  static List<BeadColor> selectRepresentativeColors(
    List<BeadColor> candidates,
    int maxCount,
  ) {
    if (candidates.length <= maxCount) return candidates;

    final selected = <BeadColor>[candidates.first];
    final remaining = candidates.sublist(1).toList();

    while (selected.length < maxCount && remaining.isNotEmpty) {
      // Find the candidate most distant from all selected colors
      BeadColor? farthest;
      double maxMinDist = -1;

      for (final candidate in remaining) {
        double minDist = double.infinity;
        for (final sel in selected) {
          final de = Ciede2000.deltaE(
            candidate.labL, candidate.labA, candidate.labB,
            sel.labL, sel.labA, sel.labB,
          );
          if (de < minDist) minDist = de;
        }
        if (minDist > maxMinDist) {
          maxMinDist = minDist;
          farthest = candidate;
        }
      }

      if (farthest != null) {
        selected.add(farthest);
        remaining.remove(farthest);
      } else {
        break;
      }
    }

    return selected;
  }

  /// Calculate the average CIEDE2000 distance between two palettes.
  static double paletteDistance(List<BeadColor> a, List<BeadColor> b) {
    if (a.isEmpty || b.isEmpty) return double.infinity;
    double totalDist = 0;
    int count = 0;
    for (final ca in a) {
      double minDist = double.infinity;
      for (final cb in b) {
        final de = Ciede2000.deltaE(
          ca.labL, ca.labA, ca.labB,
          cb.labL, cb.labA, cb.labB,
        );
        if (de < minDist) minDist = de;
      }
      totalDist += minDist;
      count++;
    }
    return totalDist / count;
  }
}
