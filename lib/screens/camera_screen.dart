import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import 'settings_select_screen.dart';
import 'gallery_screen.dart';
import 'app_settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 0;
  bool _isInitialized = false;
  bool _isTakingPhoto = false;
  bool _isStarting = false;
  bool _permissionDenied = false;
  bool _hasError = false;
  int _patternCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadPatternCount();
  }

  Future<void> _loadPatternCount() async {
    final count = await DatabaseService.getPatternCount();
    if (mounted) setState(() => _patternCount = count);
  }

  Future<void> _initCamera() async {
    setState(() {
      _hasError = false;
      _permissionDenied = false;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) setState(() => _hasError = true);
        return;
      }
      await _startCamera(_cameraIndex);
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _startCamera(int index) async {
    // Serialize start calls (resume / switch / init) to prevent double-init
    // races that leak controllers or trigger "camera in use" errors.
    if (_isStarting) return;
    _isStarting = true;
    try {
      // Reset state before reinitializing
      if (mounted) setState(() => _isInitialized = false);

      // Dispose old controller first
      final oldController = _controller;
      _controller = null;
      await oldController?.dispose();

      if (_cameras == null || _cameras!.isEmpty) return;

      final newController = CameraController(
        _cameras![index],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await newController.initialize();

        // Lock capture orientation to portrait to prevent sensor rotation issues
        await newController.lockCaptureOrientation(DeviceOrientation.portraitUp);

        // If the screen was disposed while initializing, drop the controller.
        if (!mounted) {
          await newController.dispose();
          return;
        }

        _controller = newController;
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      } catch (e) {
        debugPrint('Camera start error: $e');
        await newController.dispose();
        if (mounted) setState(() => _hasError = true);
      }
    } finally {
      _isStarting = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final c = _controller;
      if (c != null && c.value.isInitialized) {
        if (mounted) setState(() => _isInitialized = false);
        c.dispose();
        _controller = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      // Re-init even when _controller is null (it was disposed on inactive).
      _startCamera(_cameraIndex);
    }
  }

  Future<void> _takePhoto() async {
    if (_isTakingPhoto || _controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isTakingPhoto = true);
    try {
      final xFile = await _controller!.takePicture();
      if (mounted) {
        _navigateToSettings(File(xFile.path));
      }
    } catch (e) {
      debugPrint('Take photo error: $e');
    } finally {
      if (mounted) setState(() => _isTakingPhoto = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xFile != null && mounted) {
        _navigateToSettings(File(xFile.path));
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.photoLoadFailed)),
        );
      }
    }
  }

  void _navigateToSettings(File photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsSelectScreen(photoFile: photo),
      ),
    ).then((_) => _loadPatternCount());
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    _startCamera(_cameraIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    final l = AppLocalizations.of(context);
    if (_permissionDenied) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                l.cameraPermissionDenied,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => openAppSettings(),
                child: Text(
                  l.openSettings,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                l.cameraStartFailed,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _initCamera,
                child: Text(
                  l.retry,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Aspect-ratio-correct camera preview
    // Fill the screen while maintaining aspect ratio (crop overflow)
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenAspect = constraints.maxWidth / constraints.maxHeight;
        final cameraAspect = _controller!.value.aspectRatio; // width/height in landscape
        // Camera reports landscape aspect (e.g. 16/9 = 1.78)
        // In portrait mode, the preview aspect is inverted (e.g. 9/16 = 0.5625)
        final previewAspect = 1.0 / cameraAspect;

        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox(
              width: screenAspect > previewAspect
                  ? constraints.maxWidth
                  : constraints.maxHeight * previewAspect,
              height: screenAspect > previewAspect
                  ? constraints.maxWidth / previewAspect
                  : constraints.maxHeight,
              child: CameraPreview(_controller!),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview (aspect-ratio correct, fills screen)
          _buildCameraPreview(),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              color: Colors.black.withValues(alpha: 0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: my patterns + choose-photo entry
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pattern gallery button (if patterns exist)
                      if (_patternCount > 0) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GalleryScreen()),
                            ).then((_) => _loadPatternCount());
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.grid_view, color: Colors.white, size: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.gallery,
                                style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Choose-photo entry (use an existing photo) - promoted
                      // to a labelled second entry alongside the shutter.
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 1.5),
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: const Icon(Icons.photo_library, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.choosePhoto,
                              style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Center: Capture button
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                    ),
                  ),

                  // Right: Switch camera
                  GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.cameraswitch, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-right: Settings gear
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
