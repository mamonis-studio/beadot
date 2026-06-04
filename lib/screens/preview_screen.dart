import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/pattern_data.dart';

class PreviewScreen extends StatefulWidget {
  final PatternData pattern;
  const PreviewScreen({super.key, required this.pattern});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.preview)),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => setState(() => _showOriginal = true),
              onTapUp: (_) => setState(() => _showOriginal = false),
              onTapCancel: () => setState(() => _showOriginal = false),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showOriginal
                    ? _buildOriginalPhoto()
                    : _buildBeadPreview(),
              ),
            ),
          ),
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'HOLD TO COMPARE',
              style: TextStyle(
                fontSize: 11, color: Color(0xFF888888),
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalPhoto() {
    final file = File(widget.pattern.originalPhotoPath);
    if (!file.existsSync()) {
      return const Center(child: Text('Photo not found', style: TextStyle(color: Color(0xFF888888))));
    }
    return Center(
      key: const ValueKey('original'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildBeadPreview() {
    return Center(
      key: const ValueKey('bead'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: widget.pattern.columns / widget.pattern.rows,
          child: CustomPaint(
            painter: _PreviewPainter(pattern: widget.pattern),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final PatternData pattern;
  _PreviewPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = pattern.rows;
    final cols = pattern.columns;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final cellSize = cellW < cellH ? cellW : cellH;
    final offsetX = (size.width - cellSize * cols) / 2;
    final offsetY = (size.height - cellSize * rows) / 2;
    final beadRadius = cellSize * 0.45;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * cols, cellSize * rows),
      Paint()..color = const Color(0xFFF5F5F5),
    );

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final color = pattern.colorAt(y, x);
        if (color == null) continue;

        final cx = offsetX + x * cellSize + cellSize / 2;
        final cy = offsetY + y * cellSize + cellSize / 2;

        // Bead circle with slight shadow
        canvas.drawCircle(
          Offset(cx + 0.5, cy + 0.5),
          beadRadius,
          Paint()..color = const Color(0x18000000),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          beadRadius,
          Paint()..color = color.color,
        );

        // Highlight dot (center hole illusion)
        if (cellSize > 4) {
          canvas.drawCircle(
            Offset(cx - cellSize * 0.1, cy - cellSize * 0.1),
            cellSize * 0.08,
            Paint()..color = const Color(0x30FFFFFF),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => false;
}
