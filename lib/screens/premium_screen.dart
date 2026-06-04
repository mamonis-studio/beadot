import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any stale phase from a previous attempt.
    PurchaseService.phase.value = PurchasePhase.idle;
    PurchaseService.errorMessage.value = null;
    PurchaseService.isPremium.addListener(_onPremiumChanged);
    PurchaseService.phase.addListener(_onPhaseChanged);
  }

  @override
  void dispose() {
    PurchaseService.isPremium.removeListener(_onPremiumChanged);
    PurchaseService.phase.removeListener(_onPhaseChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    // Purchase/restore confirmed via the stream: close and let gated screens
    // update through their ValueListenableBuilders.
    if (PurchaseService.isPremium.value) {
      Navigator.pop(context);
    }
  }

  void _onPhaseChanged() {
    if (!mounted) return;
    if (PurchaseService.phase.value == PurchasePhase.error) {
      final l = AppLocalizations.of(context);
      final msg = PurchaseService.errorMessage.value ?? l.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.error}: $msg')),
      );
    }
    setState(() {});
  }

  Future<void> _purchase() async {
    try {
      await PurchaseService.purchasePremium();
    } catch (_) {
      // Phase/error already published; _onPhaseChanged surfaces the message.
    }
  }

  Future<void> _restore() async {
    try {
      await PurchaseService.restorePurchases();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final busy = PurchaseService.phase.value == PurchasePhase.pending;
    final alreadyPremium = PurchaseService.isPremium.value;

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
              Text(
                l.premiumTitle,
                style: const TextStyle(
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
                  onPressed: (alreadyPremium || busy) ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          alreadyPremium ? l.purchased : l.purchaseBtn,
                          style: const TextStyle(fontSize: 16, letterSpacing: 2),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Pending hint (e.g. waiting for approval / store processing)
              if (busy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l.processing,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1),
                  ),
                ),

              // Restore (hidden once already premium)
              if (!alreadyPremium)
                GestureDetector(
                  onTap: busy ? null : _restore,
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
