import 'package:flutter/material.dart';
import '../models/bead_color.dart';
import '../models/pattern_data.dart';

enum GridDisplayMode { color, symbol, number }

class BeadGridPainter extends CustomPainter {
  final PatternData pattern;
  final GridDisplayMode displayMode;
  final String? highlightColorId; // null = no highlight
  final double cellSize;

  BeadGridPainter({
    required this.pattern,
    required this.displayMode,
    this.highlightColorId,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = pattern.rows;
    final cols = pattern.columns;
    final beadDiameter = cellSize * 0.9;
    final beadRadius = beadDiameter / 2;

    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final emptyPaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final left = x * cellSize;
        final top = y * cellSize;
        final center = Offset(left + cellSize / 2, top + cellSize / 2);
        final cellRect = Rect.fromLTWH(left, top, cellSize, cellSize);

        final beadColor = pattern.colorAt(y, x);

        if (beadColor == null) {
          // Masked out cell
          canvas.drawRect(cellRect, emptyPaint);
          continue;
        }

        // Grid line
        canvas.drawRect(cellRect, gridPaint);

        // Determine opacity for highlight mode
        double opacity = 1.0;
        if (highlightColorId != null && beadColor.id != highlightColorId) {
          opacity = 0.2;
        }

        // Draw bead circle
        final beadPaint = Paint()
          ..color = beadColor.color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, beadRadius, beadPaint);

        // Draw text overlay (symbol or number)
        if (displayMode != GridDisplayMode.color && cellSize >= 8) {
          String text;
          if (displayMode == GridDisplayMode.symbol) {
            text = beadColor.symbol;
          } else {
            // Number mode: index in used colors
            final index = pattern.usedColors.keys.toList().indexOf(beadColor.id);
            text = '${index + 1}';
          }

          final textPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: beadColor.contrastTextColor.withValues(alpha: opacity),
                fontSize: cellSize * 0.55,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              center.dx - textPainter.width / 2,
              center.dy - textPainter.height / 2,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BeadGridPainter oldDelegate) {
    return oldDelegate.displayMode != displayMode ||
        oldDelegate.highlightColorId != highlightColorId ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.pattern != pattern;
  }
}
