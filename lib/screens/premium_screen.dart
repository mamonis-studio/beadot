import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _purchasing = false;

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    try {
      await PurchaseService.purchasePremium();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    try {
      await PurchaseService.restorePurchases();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Title
              const Text(
                'PREMIUM',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 12,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 48),

              // Features
              _featureRow(l.unlimitedGen),
              _featureRow(l.multiPlate),
              _featureRow(l.customSize),
              _featureRow(l.realSizePdf),
              _featureRow(l.noWatermark),

              const Spacer(flex: 2),

              // Purchase button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _purchasing ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                  ),
                  child: _purchasing
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          l.purchaseBtn,
                          style: const TextStyle(fontSize: 16, letterSpacing: 2),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Restore
              GestureDetector(
                onTap: _purchasing ? null : _restore,
                child: Text(
                  l.restore,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF111111), width: 1.5),
            ),
            child: const Icon(Icons.check, size: 14, color: Color(0xFF111111)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}
