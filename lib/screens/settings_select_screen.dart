import 'dart:io';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/bead_brand.dart';
import '../models/conversion_settings.dart';
import '../models/plate_shape.dart';
import '../models/plate_size.dart';
import '../services/preference_service.dart';
import '../widgets/plate_shape_selector.dart';
import '../widgets/segment_control.dart';
import 'crop_screen.dart';

class SettingsSelectScreen extends StatefulWidget {
  final File photoFile;
  const SettingsSelectScreen({super.key, required this.photoFile});

  @override
  State<SettingsSelectScreen> createState() => _SettingsSelectScreenState();
}

class _SettingsSelectScreenState extends State<SettingsSelectScreen> {
  BeadBrand _brand = BeadBrand.perler;
  PlateShape _shape = PlateShape.square;
  PlateSize _size = PlateSize.s;
  DitherMode _ditherMode = DitherMode.direct;
  double _ditherStrength = 0.5;
  int _maxColors = 12;
  ColorFilter _colorFilter = ColorFilter.solidOnly;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final brand = await PreferenceService.getDefaultBrand();
    final premium = await PreferenceService.isPremium();
    setState(() {
      _brand = brand;
      _isPremium = premium;
      _maxColors = ConversionDefaults.defaultMaxColors(_size.columns);
    });
  }

  List<PlateSize> get _availableSizes {
    switch (_shape) {
      case PlateShape.square:
        return PlateSize.squareSizes;
      case PlateShape.hexagon:
        return PlateSize.hexSizes;
      case PlateShape.circle:
      case PlateShape.star:
        return PlateSize.circleSizes;
      case PlateShape.heart:
        return PlateSize.heartSizes;
    }
  }

  void _onShapeChanged(PlateShape shape) {
    setState(() {
      _shape = shape;
      // Reset size if current isn't available for new shape
      final sizes = _availableSizes;
      if (!sizes.contains(_size)) {
        _size = sizes.first;
      }
      _maxColors = ConversionDefaults.defaultMaxColors(_size.columns);
    });
  }

  void _onSizeChanged(PlateSize size) {
    if (size.isPremium && !_isPremium) {
      _showPremiumDialog();
      return;
    }
    setState(() {
      _size = size;
      _maxColors = ConversionDefaults.defaultMaxColors(size.columns);
    });
  }

  void _showPremiumDialog() {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.premiumRequired)),
    );
  }

  void _showCustomSizeDialog() {
    if (!_isPremium) {
      _showPremiumDialog();
      return;
    }
    int cols = 32, rows = 32;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CUSTOM SIZE', style: TextStyle(letterSpacing: 2, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Columns (8-128)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => cols = int.tryParse(v) ?? 32,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Rows (8-128)'),
              keyboardType: TextInputType.number,
              onChanged: (v) => rows = int.tryParse(v) ?? 32,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _size = PlateSize.custom(cols, rows);
                _maxColors = ConversionDefaults.defaultMaxColors(_size.columns);
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _proceed() {
    final settings = ConversionSettings(
      brand: _brand,
      shape: _shape,
      size: _size,
      ditherMode: _ditherMode,
      ditherStrength: _ditherStrength,
      maxColors: _maxColors,
      colorFilter: _colorFilter,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(
          photoFile: widget.photoFile,
          settings: settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.selectSettings),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo preview
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.photoFile,
                  width: 120, height: 120, fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // BRAND
            _sectionLabel(l.brand),
            const SizedBox(height: 8),
            SegmentControl<BeadBrand>(
              items: const [BeadBrand.perler, BeadBrand.nano, BeadBrand.hamaMidi],
              selected: _brand,
              labelBuilder: (b) {
                switch (b) {
                  case BeadBrand.perler: return l.perler;
                  case BeadBrand.nano: return l.nano;
                  case BeadBrand.hamaMidi: return l.hama;
                  default: return b.displayNameEn;
                }
              },
              onChanged: (b) {
                setState(() {
                  _brand = b;
                  if (!b.supportsSpecialShapes && _shape != PlateShape.square) {
                    _shape = PlateShape.square;
                  }
                });
              },
            ),

            // COLOR TYPE (Perler only)
            if (_brand == BeadBrand.perler) ...[
              const SizedBox(height: 16),
              _sectionLabel('COLOR TYPE'),
              const SizedBox(height: 8),
              SegmentControl<ColorFilter>(
                items: ColorFilter.values,
                selected: _colorFilter,
                labelBuilder: (f) {
                  switch (f) {
                    case ColorFilter.solidOnly: return l.solidOnly;
                    case ColorFilter.includePearl: return l.includePearl;
                    case ColorFilter.all: return l.allColors;
                  }
                },
                onChanged: (f) => setState(() => _colorFilter = f),
              ),
            ],

            // PLATE SHAPE
            const SizedBox(height: 16),
            _sectionLabel(l.plateShape),
            const SizedBox(height: 8),
            PlateShapeSelector(
              selected: _shape,
              onChanged: _onShapeChanged,
              onlySquare: !_brand.supportsSpecialShapes,
            ),

            // PLATE SIZE
            const SizedBox(height: 16),
            _sectionLabel(l.plateSize),
            const SizedBox(height: 8),
            ..._buildSizeButtons(),

            // QUALITY
            const SizedBox(height: 16),
            _sectionLabel(l.quality),
            const SizedBox(height: 8),
            SegmentControl<DitherMode>(
              items: DitherMode.values,
              selected: _ditherMode,
              labelBuilder: (d) => d == DitherMode.direct ? l.direct : l.dither,
              onChanged: (d) => setState(() => _ditherMode = d),
            ),

            // Dither strength slider
            if (_ditherMode == DitherMode.floydSteinberg) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(l.ditherStrength, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  Expanded(
                    child: Slider(
                      value: _ditherStrength,
                      min: 0, max: 1,
                      activeColor: const Color(0xFF111111),
                      inactiveColor: const Color(0xFFE0E0E0),
                      onChanged: (v) => setState(() => _ditherStrength = v),
                    ),
                  ),
                  Text('${(_ditherStrength * 100).round()}%',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                ],
              ),
            ],

            // MAX COLORS
            const SizedBox(height: 12),
            _sectionLabel(l.maxColors),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxColors.toDouble(),
                    min: 5, max: 50,
                    divisions: 45,
                    activeColor: const Color(0xFF111111),
                    inactiveColor: const Color(0xFFE0E0E0),
                    onChanged: (v) => setState(() => _maxColors = v.round()),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_maxColors${l.colors}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            // Hint
            const SizedBox(height: 8),
            Text(
              _size.columns <= 15 ? l.hintSmallDirect : l.hintLargeDither,
              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),

            const SizedBox(height: 32),

            // Proceed button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('NEXT', style: TextStyle(fontSize: 16, letterSpacing: 4)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF888888), letterSpacing: 1),
    );
  }

  List<Widget> _buildSizeButtons() {
    final sizes = _availableSizes;
    final buttons = <Widget>[];

    for (final size in sizes) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _onSizeChanged(size),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _size == size ? const Color(0xFF111111) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF111111), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${size.label} — ${size.displaySize}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _size == size ? Colors.white : const Color(0xFF111111),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (size.isPremium && !_isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF888888),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Custom size button (square only)
    if (_shape == PlateShape.square) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: _showCustomSizeDialog,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _size.label == 'CUSTOM' ? const Color(0xFF111111) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF111111), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _size.label == 'CUSTOM' ? 'CUSTOM — ${_size.displaySize}' : 'CUSTOM',
                    style: TextStyle(
                      fontSize: 16,
                      color: _size.label == 'CUSTOM' ? Colors.white : const Color(0xFF111111),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!_isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF888888),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return buttons;
  }
}
