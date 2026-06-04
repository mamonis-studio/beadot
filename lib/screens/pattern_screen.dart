import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/bead_color.dart';
import '../models/pattern_data.dart';
import '../models/plate_shape.dart';
import '../data/bead_colors_loader.dart';
import '../services/conversion_service.dart';
import '../services/preference_service.dart';
import '../widgets/bead_grid_painter.dart';
import '../widgets/hex_grid_painter.dart';
import '../widgets/color_palette_bar.dart';
import '../widgets/segment_control.dart';
import 'shopping_list_screen.dart';
import 'preview_screen.dart';

class PatternScreen extends StatefulWidget {
  final PatternData pattern;
  const PatternScreen({super.key, required this.pattern});

  @override
  State<PatternScreen> createState() => _PatternScreenState();
}

class _PatternScreenState extends State<PatternScreen> {
  late PatternData _pattern;
  GridDisplayMode _displayMode = GridDisplayMode.color;
  String? _highlightColorId;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _pattern = widget.pattern;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _showAdjustColorsDialog() async {
    final l = AppLocalizations.of(context);
    int newMax = _pattern.usedColorCount;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.adjustColors, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: newMax.toDouble(),
                      min: 3, max: 50, divisions: 47,
                      activeColor: const Color(0xFF111111),
                      onChanged: (v) => setSheetState(() => newMax = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text('$newMax${l.colors}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _reoptimize(newMax);
                  },
                  child: const Text('APPLY', style: TextStyle(letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reoptimize(int newMaxColors) async {
    final allColors = await BeadColorsLoader.loadColors(_pattern.settings.brand);
    final palette = BeadColorsLoader.filterPalette(allColors, _pattern.settings.colorFilter);
    final removeIsolated = await PreferenceService.getRemoveIsolated();

    final newGrid = ConversionService.reoptimize(
      originalGrid: _pattern.grid,
      palette: palette,
      newMaxColors: newMaxColors,
      removeIsolated: removeIsolated,
    );

    // Recalculate used colors
    final usedIds = <String>{};
    for (final row in newGrid) {
      for (final cell in row) {
        if (cell.isNotEmpty) usedIds.add(cell);
      }
    }
    final paletteMap = {for (final c in palette) c.id: c};
    final usedColors = <String, BeadColor>{};
    for (final id in usedIds) {
      if (paletteMap.containsKey(id)) usedColors[id] = paletteMap[id]!;
    }

    setState(() {
      _pattern = PatternData(
        dbId: _pattern.dbId,
        createdAt: _pattern.createdAt,
        settings: _pattern.settings.copyWith(maxColors: newMaxColors),
        grid: newGrid,
        usedColors: usedColors,
        originalPhotoPath: _pattern.originalPhotoPath,
        title: _pattern.title,
      );
      _highlightColorId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isHex = _pattern.settings.shape == PlateShape.hexagon;
    final cols = _pattern.columns;
    final rows = _pattern.rows;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () {
            // Pop all the way back to camera
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: Text('${_pattern.usedColorCount}${l.colors}  ${_pattern.totalBeads}${l.pieces}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, size: 24),
            onPressed: _showActionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Display mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: SegmentControl<GridDisplayMode>(
              items: GridDisplayMode.values,
              selected: _displayMode,
              labelBuilder: (m) {
                switch (m) {
                  case GridDisplayMode.color: return l.colorMode;
                  case GridDisplayMode.symbol: return l.symbolMode;
                  case GridDisplayMode.number: return l.numberMode;
                }
              },
              onChanged: (m) => setState(() => _displayMode = m),
              height: 32,
            ),
          ),

          // Grid area (pinch-to-zoom)
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth - 16;
                    final maxH = constraints.maxHeight - 16;
                    final cellW = maxW / cols;
                    final cellH = isHex ? maxH / (rows * 0.866 + 0.5) : maxH / rows;
                    final cellSize = cellW < cellH ? cellW : cellH;

                    final canvasW = isHex ? cols * cellSize + cellSize * 0.5 : cols * cellSize;
                    final canvasH = isHex ? rows * cellSize * 0.866 + cellSize : rows * cellSize;

                    return SizedBox(
                      width: canvasW,
                      height: canvasH,
                      child: CustomPaint(
                        painter: isHex
                            ? HexGridPainter(
                                pattern: _pattern,
                                displayMode: _displayMode,
                                highlightColorId: _highlightColorId,
                                cellSize: cellSize,
                              )
                            : BeadGridPainter(
                                pattern: _pattern,
                                displayMode: _displayMode,
                                highlightColorId: _highlightColorId,
                                cellSize: cellSize,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Palette bar
          ColorPaletteBar(
            pattern: _pattern,
            highlightColorId: _highlightColorId,
            onColorTap: (id) => setState(() => _highlightColorId = id),
            locale: AppLocalizations.of(context).locale,
          ),
        ],
      ),
    );
  }

  void _showActionsMenu() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            _actionTile(Icons.palette, l.adjustColors, () {
              Navigator.pop(ctx);
              _showAdjustColorsDialog();
            }),
            _actionTile(Icons.image, l.preview, () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PreviewScreen(pattern: _pattern),
              ));
            }),
            _actionTile(Icons.shopping_cart, l.shoppingList, () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ShoppingListScreen(pattern: _pattern),
              ));
            }),
            _actionTile(Icons.picture_as_pdf, l.pdfExport, () {
              Navigator.pop(ctx);
              _exportPdf();
            }),
            _actionTile(Icons.share, l.share, () {
              Navigator.pop(ctx);
              _sharePattern();
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF111111), size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  void _exportPdf() {
    // PDF export will be handled by PdfService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export coming soon')),
    );
  }

  void _sharePattern() {
    // Share will be handled by share_plus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share coming soon')),
    );
  }
}
