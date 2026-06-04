import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/pattern_data.dart';
import '../services/database_service.dart';
import 'pattern_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<PatternData> _patterns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatterns();
  }

  Future<void> _loadPatterns() async {
    final patterns = await DatabaseService.getAllPatterns();
    if (mounted) setState(() { _patterns = patterns; _loading = false; });
  }

  Future<void> _deletePattern(PatternData pattern) async {
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && pattern.dbId != null) {
      await DatabaseService.deletePattern(pattern.dbId!);
      // Delete photo file
      try { await File(pattern.originalPhotoPath).delete(); } catch (_) {}
      _loadPatterns();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.gallery)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF111111)))
          : _patterns.isEmpty
              ? Center(child: Text(l.noPatterns, style: const TextStyle(color: Color(0xFF888888))))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _patterns.length,
                  itemBuilder: (context, index) {
                    final pattern = _patterns[index];
                    return _GalleryTile(
                      pattern: pattern,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PatternScreen(pattern: pattern)),
                        ).then((_) => _loadPatterns());
                      },
                      onLongPress: () => _deletePattern(pattern),
                    );
                  },
                ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final PatternData pattern;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GalleryTile({
    required this.pattern,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: _buildMiniGrid(pattern),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pattern.settings.brand.displayNameEn,
                    style: const TextStyle(fontSize: 8, color: Color(0xFF888888)),
                  ),
                  Text(
                    pattern.settings.size.displaySize,
                    style: const TextStyle(fontSize: 8, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniGrid(PatternData pattern) {
    return CustomPaint(
      painter: _MiniGridPainter(pattern: pattern),
      size: Size.infinite,
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  final PatternData pattern;
  _MiniGridPainter({required this.pattern});

  @override
  void paint(Canvas canvas, Size size) {
    final rows = pattern.rows;
    final cols = pattern.columns;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final cellSize = cellW < cellH ? cellW : cellH;
    final offsetX = (size.width - cellSize * cols) / 2;
    final offsetY = (size.height - cellSize * rows) / 2;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final color = pattern.colorAt(y, x);
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            offsetX + x * cellSize, offsetY + y * cellSize,
            cellSize, cellSize,
          ),
          Paint()..color = color.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniGridPainter old) => false;
}
