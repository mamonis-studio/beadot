import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/bead_colors_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Preload bead color data
  await BeadColorsLoader.preloadAll();

  runApp(const BeadotApp());
}
