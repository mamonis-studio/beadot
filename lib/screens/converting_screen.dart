import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../l10n/app_localizations.dart';
import '../models/bead_color.dart';
import '../models/conversion_settings.dart';
import '../models/pattern_data.dart';
import '../data/bead_colors_loader.dart';
import '../services/conversion_service.dart';
import '../services/database_service.dart';
import '../services/preference_service.dart';
import 'pattern_screen.dart';

class ConvertingScreen extends StatefulWidget {
  final img.Image croppedImage;
  final ConversionSettings settings;
  final File originalPhotoFile;

  const ConvertingScreen({
    super.key,
    required this.croppedImage,
    required this.settings,
    required this.originalPhotoFile,
  });

  @override
  State<ConvertingScreen> createState() => _ConvertingScreenState();
}

class _ConvertingScreenState extends State<ConvertingScreen> {
  double _progress = 0.0;
  String _stage = '';
  bool _cancelled = false;
  bool _converting = false;

  @override
  void initState() {
    super.initState();
    _startConversion();
  }

  Future<void> _startConversion() async {
    if (_converting) return;
    _converting = true;

    // Check daily limit
    final canGenerate = await PreferenceService.canGenerateToday();
    if (!canGenerate && mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.dailyLimitReached)),
      );
      Navigator.pop(context);
      return;
    }

    try {
      // Load palette
      final allColors = await BeadColorsLoader.loadColors(widget.settings.brand);
      final palette = BeadColorsLoader.filterPalette(allColors, widget.settings.colorFilter);
      final removeIsolated = await PreferenceService.getRemoveIsolated();

      if (_cancelled) return;

      final result = await ConversionService.convert(
        croppedImage: widget.croppedImage,
        settings: widget.settings,
        palette: palette,
        removeIsolatedPixels: removeIsolated,
        onProgress: (stage, value) {
          if (mounted && !_cancelled) {
            setState(() {
              _stage = stage;
              _progress = value;
            });
          }
        },
      );

      if (_cancelled || !mounted) return;

      // Save original photo
      final docsDir = await getApplicationDocumentsDirectory();
      final photoName = 'photo_${DateTime.now().millisecondsSinceEpoch}.png';
      final photoPath = p.join(docsDir.path, 'photos', photoName);
      await Directory(p.dirname(photoPath)).create(recursive: true);
      await File(photoPath).writeAsBytes(img.encodePng(widget.croppedImage));

      // Build PatternData
      final usedColors = result.usedColorsJson.map(
        (k, v) => MapEntry(k, BeadColor.fromJson(v)),
      );

      final pattern = PatternData(
        createdAt: DateTime.now(),
        settings: widget.settings,
        grid: result.grid,
        usedColors: usedColors,
        originalPhotoPath: photoPath,
      );

      // Save to DB
      final dbId = await DatabaseService.savePattern(pattern);
      await PreferenceService.recordGeneration();

      final savedPattern = PatternData(
        dbId: dbId,
        createdAt: pattern.createdAt,
        settings: pattern.settings,
        grid: pattern.grid,
        usedColors: pattern.usedColors,
        originalPhotoPath: pattern.originalPhotoPath,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatternScreen(pattern: savedPattern),
          ),
        );
      }
    } catch (e) {
      if (mounted && !_cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _cancelled = true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.converting,
                  style: const TextStyle(
                    fontSize: 16,
                    letterSpacing: 4,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 24),
                // Progress bar
                Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () {
                    _cancelled = true;
                    Navigator.pop(context);
                  },
                  child: Text(
                    l.cancel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
