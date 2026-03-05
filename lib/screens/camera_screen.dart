import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;
    await _startCamera(_cameraIndex);
  }

  Future<void> _startCamera(int index) async {
    _controller?.dispose();
    _controller = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
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
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (xFile != null && mounted) {
      _navigateToSettings(File(xFile.path));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

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
                  // Left: Gallery + Gallery icon
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pattern gallery button (if patterns exist)
                      if (_patternCount > 0)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GalleryScreen()),
                            ).then((_) => _loadPatternCount());
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.grid_view, color: Colors.white, size: 20),
                          ),
                        ),
                      // Gallery picker
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: const Icon(Icons.photo_library, color: Colors.white, size: 20),
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
