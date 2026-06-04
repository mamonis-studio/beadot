import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/bead_colors_loader.dart';
import 'services/purchase_service.dart';

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

  // Seed premium entitlement (cheap prefs read) so gated UI is correct
  // on the first frame.
  await PurchaseService.seedPremium();

  runApp(const BeadotApp());

  // Start listening to the purchase stream after the first frame so the
  // platform availability check does not delay startup. Interrupted/pending
  // transactions are still delivered once the listener attaches.
  PurchaseService.startListening();
}
