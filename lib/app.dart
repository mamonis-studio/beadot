import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants.dart';
import 'l10n/app_localizations.dart';
import 'screens/camera_screen.dart';
import 'services/preference_service.dart';

class BeadotApp extends StatefulWidget {
  const BeadotApp({super.key});

  static BeadotAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<BeadotAppState>();

  @override
  State<BeadotApp> createState() => BeadotAppState();
}

class BeadotAppState extends State<BeadotApp> {
  bool _isDarkMode = false;
  Locale _locale = const Locale('ja');

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final dark = await PreferenceService.getDarkMode();
    final lang = await PreferenceService.getLanguage();
    setState(() {
      _isDarkMode = dark;
      _locale = Locale(lang);
    });
  }

  void setDarkMode(bool value) {
    setState(() => _isDarkMode = value);
    PreferenceService.setDarkMode(value);
  }

  void setLocale(String lang) {
    setState(() => _locale = Locale(lang));
    PreferenceService.setLanguage(lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'beadot',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('ja'), Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.text,
          onPrimary: Colors.white,
          surface: AppColors.background,
          onSurface: AppColors.text,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 4,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.text, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.secondary, fontSize: 12),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.darkText,
          onPrimary: AppColors.darkBackground,
          surface: AppColors.darkBackground,
          onSurface: AppColors.darkText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 4,
          ),
        ),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const CameraScreen(),
    );
  }
}
