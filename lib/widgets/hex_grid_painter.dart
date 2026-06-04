import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pattern_data.dart';
import 'bead_grid_painter.dart';

/// Draws beads in hexagonal offset grid (staggered layout).
/// Odd rows are offset by 0.5 cell width to the right.
class HexGridPainter extends CustomPainter {
  final PatternData pattern;
  final GridDisplayMode displayMode;
  final String? highlightColorId;
  final double cellSize;

  HexGridPainter({
    required this.pattern,
    required this.displayMode,
    this.highlightColorId,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = pattern.rows;
    final cols = pattern.columns;
    final beadRadius = cellSize * 0.45;
    final rowHeight = cellSize * 0.866; // sqrt(3)/2

    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int y = 0; y < rows; y++) {
      final isOddRow = y % 2 == 1;
      final xOffset = isOddRow ? cellSize * 0.5 : 0.0;

      for (int x = 0; x < cols; x++) {
        final cx = x * cellSize + cellSize / 2 + xOffset;
        final cy = y * rowHeight + cellSize / 2;
        final center = Offset(cx, cy);

        final beadColor = pattern.colorAt(y, x);
        if (beadColor == null) continue;

        double opacity = 1.0;
        if (highlightColorId != null && beadColor.id != highlightColorId) {
          opacity = 0.2;
        }

        // Draw hexagonal outline (optional, subtle)
        _drawHexOutline(canvas, center, cellSize * 0.48, gridPaint);

        // Draw bead circle
        final beadPaint = Paint()
          ..color = beadColor.color.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, beadRadius, beadPaint);

        // Text overlay
        if (displayMode != GridDisplayMode.color && cellSize >= 8) {
          String text;
          if (displayMode == GridDisplayMode.symbol) {
            text = beadColor.symbol;
          } else {
            final index = pattern.usedColors.keys.toList().indexOf(beadColor.id);
            text = '${index + 1}';
          }

          final textPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: beadColor.contrastTextColor.withValues(alpha: opacity),
                fontSize: cellSize * 0.45,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
          );
        }
      }
    }
  }

  void _drawHexOutline(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60.0 * i - 30.0) * pi / 180.0;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HexGridPainter oldDelegate) {
    return oldDelegate.displayMode != displayMode ||
        oldDelegate.highlightColorId != highlightColorId ||
        oldDelegate.cellSize != cellSize;
  }
}
