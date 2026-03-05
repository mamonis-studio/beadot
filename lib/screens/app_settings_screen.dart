import 'package:flutter/material.dart';
import '../app.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../models/bead_brand.dart';
import '../services/preference_service.dart';
import 'premium_screen.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl, Uri;

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  BeadBrand _defaultBrand = BeadBrand.perler;
  bool _removeIsolated = true;
  bool _darkMode = false;
  String _language = 'ja';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final brand = await PreferenceService.getDefaultBrand();
    final iso = await PreferenceService.getRemoveIsolated();
    final dark = await PreferenceService.getDarkMode();
    final lang = await PreferenceService.getLanguage();
    final prem = await PreferenceService.isPremium();
    if (mounted) {
      setState(() {
        _defaultBrand = brand;
        _removeIsolated = iso;
        _darkMode = dark;
        _language = lang;
        _isPremium = prem;
      });
    }
  }

  void _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          // Premium
          if (!_isPremium)
            _buildTile(
              icon: Icons.star,
              label: l.premiumTitle,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()))
                    .then((_) => _loadSettings());
              },
            ),

          const _SectionDivider(),

          // Default brand
          _buildTile(
            icon: Icons.circle,
            label: l.defaultBrand,
            trailing: Text(_defaultBrand.displayNameEn, style: const TextStyle(color: Color(0xFF888888))),
            onTap: () => _showBrandPicker(),
          ),

          // Remove isolated pixels
          _buildSwitchTile(
            icon: Icons.blur_off,
            label: l.removeIsolated,
            value: _removeIsolated,
            onChanged: (v) {
              setState(() => _removeIsolated = v);
              PreferenceService.setRemoveIsolated(v);
            },
          ),

          const _SectionDivider(),

          // Dark mode
          _buildSwitchTile(
            icon: Icons.dark_mode,
            label: l.darkMode,
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              BeadotApp.of(context)?.setDarkMode(v);
            },
          ),

          // Language
          _buildTile(
            icon: Icons.language,
            label: l.language,
            trailing: Text(_languageLabel(_language), style: const TextStyle(color: Color(0xFF888888))),
            onTap: () => _showLanguagePicker(),
          ),

          const _SectionDivider(),

          // Privacy Policy
          _buildTile(
            icon: Icons.shield,
            label: l.privacyPolicy,
            onTap: () => _openUrl(AppStrings.privacyUrl),
          ),

          // Terms
          _buildTile(
            icon: Icons.description,
            label: l.termsOfUse,
            onTap: () => _openUrl(AppStrings.termsUrl),
          ),

          // Contact
          _buildTile(
            icon: Icons.email,
            label: l.contact,
            onTap: () => _openUrl('mailto:${AppStrings.contactEmail}'),
          ),

          const _SectionDivider(),

          // Version
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              '${l.version} 1.0.0',
              style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
            ),
          ),

          // Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.disclaimer,
              style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: const Color(0xFF111111)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCCC)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: const Color(0xFF111111)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF111111),
      ),
    );
  }

  void _showBrandPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: BeadBrand.values
              .where((b) => b != BeadBrand.hamaMini) // ハマミニはミディと同じデータ
              .map((brand) => ListTile(
                    title: Text(brand.displayNameEn),
                    trailing: brand == _defaultBrand
                        ? const Icon(Icons.check, color: Color(0xFF111111))
                        : null,
                    onTap: () {
                      setState(() => _defaultBrand = brand);
                      PreferenceService.setDefaultBrand(brand);
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langTile(ctx, 'ja', '日本語'),
            _langTile(ctx, 'en', 'English'),
            _langTile(ctx, 'zh', '中文'),
          ],
        ),
      ),
    );
  }

  Widget _langTile(BuildContext ctx, String code, String label) {
    return ListTile(
      title: Text(label),
      trailing: code == _language ? const Icon(Icons.check, color: Color(0xFF111111)) : null,
      onTap: () {
        setState(() => _language = code);
        BeadotApp.of(context)?.setLocale(code);
        Navigator.pop(ctx);
      },
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'ja': return '日本語';
      case 'en': return 'English';
      case 'zh': return '中文';
      default: return code;
    }
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 56, endIndent: 16);
}
