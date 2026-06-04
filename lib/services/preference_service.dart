import 'package:shared_preferences/shared_preferences.dart';
import '../models/bead_brand.dart';

class PreferenceService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Keys
  static const _keyDefaultBrand = 'default_brand';
  static const _keyDarkMode = 'dark_mode';
  static const _keyLanguage = 'language';
  static const _keyRemoveIsolated = 'remove_isolated';
  static const _keyPremium = 'is_premium';
  static const _keyLastGenerationDate = 'last_generation_date';
  static const _keyGenerationCount = 'generation_count_today';

  /// Default brand
  static Future<BeadBrand> getDefaultBrand() async {
    final p = await prefs;
    final index = p.getInt(_keyDefaultBrand) ?? 0;
    return BeadBrand.values[index.clamp(0, BeadBrand.values.length - 1)];
  }

  static Future<void> setDefaultBrand(BeadBrand brand) async {
    final p = await prefs;
    await p.setInt(_keyDefaultBrand, brand.index);
  }

  /// Dark mode
  static Future<bool> getDarkMode() async {
    final p = await prefs;
    return p.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final p = await prefs;
    await p.setBool(_keyDarkMode, value);
  }

  /// Language (ja, en, zh)
  static Future<String> getLanguage() async {
    final p = await prefs;
    return p.getString(_keyLanguage) ?? 'ja';
  }

  static Future<void> setLanguage(String lang) async {
    final p = await prefs;
    await p.setString(_keyLanguage, lang);
  }

  /// Remove isolated pixels
  static Future<bool> getRemoveIsolated() async {
    final p = await prefs;
    return p.getBool(_keyRemoveIsolated) ?? true;
  }

  static Future<void> setRemoveIsolated(bool value) async {
    final p = await prefs;
    await p.setBool(_keyRemoveIsolated, value);
  }

  /// Premium status
  static Future<bool> isPremium() async {
    final p = await prefs;
    return p.getBool(_keyPremium) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    final p = await prefs;
    await p.setBool(_keyPremium, value);
  }

  /// Free version daily limit check.
  /// Resets at device local midnight.
  static Future<bool> canGenerateToday() async {
    final premium = await isPremium();
    if (premium) return true;

    final p = await prefs;
    final lastDate = p.getString(_keyLastGenerationDate);
    final today = _todayString();

    if (lastDate != today) {
      // New day: reset counter
      return true;
    }

    final count = p.getInt(_keyGenerationCount) ?? 0;
    return count < 1; // Free version: 1 per day
  }

  /// Record a generation.
  static Future<void> recordGeneration() async {
    final p = await prefs;
    final today = _todayString();
    final lastDate = p.getString(_keyLastGenerationDate);

    if (lastDate != today) {
      await p.setString(_keyLastGenerationDate, today);
      await p.setInt(_keyGenerationCount, 1);
    } else {
      final count = p.getInt(_keyGenerationCount) ?? 0;
      await p.setInt(_keyGenerationCount, count + 1);
    }
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
