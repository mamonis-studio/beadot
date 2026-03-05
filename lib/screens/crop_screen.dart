import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/conversion_settings.dart';
import '../models/plate_shape.dart';
import 'converting_screen.dart';

class CropScreen extends StatefulWidget {
  final File photoFile;
  final ConversionSettings settings;

  const CropScreen({super.key, required this.photoFile, required this.settings});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  Size _imageSize = Size.zero;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await widget.photoFile.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    if (mounted) {
      setState(() {
        _imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
        _imageLoaded = true;
      });
    }
  }

  double get _cropAspectRatio {
    final size = widget.settings.size;
    return size.columns / size.rows;
  }

  Rect _getCropRect(Size viewSize) {
    final padding = 32.0;
    final availW = viewSize.width - padding * 2;
    final availH = viewSize.height - padding * 2 - 120; // bottom area

    double cropW, cropH;
    final aspect = _cropAspectRatio;
    if (availW / availH > aspect) {
      cropH = availH;
      cropW = cropH * aspect;
    } else {
      cropW = availW;
      cropH = cropW / aspect;
    }

    return Rect.fromCenter(
      center: Offset(viewSize.width / 2, (viewSize.height - 120) / 2),
      width: cropW,
      height: cropH,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _baseOffset = _offset;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_baseScale * details.scale).clamp(0.5, 5.0);
      _offset = _baseOffset + details.focalPointDelta;
    });
  }

  Future<void> _confirm() async {
    if (!_imageLoaded) return;

    final viewSize = MediaQuery.of(context).size;
    final cropRect = _getCropRect(viewSize);

    // Calculate the crop region in image coordinates
    final displayW = _imageSize.width * _scale;
    final displayH = _imageSize.height * _scale;
    final displayLeft = (viewSize.width - displayW) / 2 + _offset.dx;
    final displayTop = ((viewSize.height - 120) - displayH) / 2 + _offset.dy;

    final scaleToImage = _imageSize.width / displayW;

    final imgCropX = ((cropRect.left - displayLeft) * scaleToImage).round().clamp(0, _imageSize.width.toInt());
    final imgCropY = ((cropRect.top - displayTop) * scaleToImage).round().clamp(0, _imageSize.height.toInt());
    final imgCropW = (cropRect.width * scaleToImage).round().clamp(1, _imageSize.width.toInt() - imgCropX);
    final imgCropH = (cropRect.height * scaleToImage).round().clamp(1, _imageSize.height.toInt() - imgCropY);

    final bytes = await widget.photoFile.readAsBytes();
    final source = img.decodeImage(bytes);
    if (source == null) return;

    final cropped = img.copyCrop(
      source,
      x: imgCropX,
      y: imgCropY,
      width: imgCropW,
      height: imgCropH,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConvertingScreen(
            croppedImage: cropped,
            settings: widget.settings,
            originalPhotoFile: widget.photoFile,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewSize = MediaQuery.of(context).size;
    final settings = widget.settings;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image layer
          GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: _imageLoaded
                ? Transform.translate(
                    offset: _offset,
                    child: Transform.scale(
                      scale: _scale,
                      child: Image.file(widget.photoFile, fit: BoxFit.contain),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),

          // Crop overlay
          if (_imageLoaded)
            LayoutBuilder(
              builder: (context, constraints) {
                final cropRect = _getCropRect(Size(constraints.maxWidth, constraints.maxHeight));
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CropOverlayPainter(
                    cropRect: cropRect,
                    shape: settings.shape,
                  ),
                );
              },
            ),

          // Bottom bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 120,
              color: Colors.black.withValues(alpha: 0.85),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Settings summary
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        settings.summaryText,
                        style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 56, height: 56,
                          child: Icon(Icons.close, color: Colors.white, size: 28),
                        ),
                      ),
                      // Confirm
                      GestureDetector(
                        onTap: _confirm,
                        child: Container(
                          width: 56, height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.check, color: Colors.black, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final PlateShape shape;

  _CropOverlayPainter({required this.cropRect, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    // Draw dim areas around crop
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), dimPaint);

    // Cut out the crop area
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    _drawShapePath(canvas, clearPaint);
    canvas.restore();

    // Crop border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawShapePath(canvas, borderPaint, stroke: true);
  }

  void _drawShapePath(Canvas canvas, Paint paint, {bool stroke = false}) {
    switch (shape) {
      case PlateShape.square:
      case PlateShape.hexagon:
        canvas.drawRect(cropRect, paint);
        break;
      case PlateShape.circle:
        canvas.drawOval(cropRect, paint);
        break;
      case PlateShape.heart:
        _drawHeart(canvas, paint);
        break;
      case PlateShape.star:
        _drawStar(canvas, paint);
        break;
    }
  }

  void _drawHeart(Canvas canvas, Paint paint) {
    final cx = cropRect.center.dx;
    final cy = cropRect.center.dy;
    final w = cropRect.width / 2;
    final h = cropRect.height / 2;

    final path = Path();
    const steps = 100;
    for (int i = 0; i <= steps; i++) {
      final t = 2 * pi * i / steps;
      // Heart parametric: x = 16sin^3(t), y = 13cos(t)-5cos(2t)-2cos(3t)-cos(4t)
      final x = 16 * pow(sin(t), 3);
      final y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t));
      final px = cx + x / 16 * w;
      final py = cy + y / 17 * h;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Paint paint) {
    final cx = cropRect.center.dx;
    final cy = cropRect.center.dy;
    final outerR = min(cropRect.width, cropRect.height) / 2;
    final innerR = outerR * 0.38;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -pi / 2 + i * pi / 5;
      final r = i.isEven ? outerR : innerR;
      final px = cx + r * cos(angle);
      final py = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.shape != shape;
  }
}
