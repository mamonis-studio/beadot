import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants.dart';
import 'preference_service.dart';

/// High-level state of the current purchase flow, observable by the UI.
enum PurchasePhase { idle, pending, error }

class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _listening = false;

  /// Premium entitlement. Seeded from local prefs at startup and updated live
  /// when a purchase/restore is delivered through the stream.
  static final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  /// Current phase of the purchase flow (idle / pending / error).
  static final ValueNotifier<PurchasePhase> phase =
      ValueNotifier<PurchasePhase>(PurchasePhase.idle);

  /// Last error message; valid while [phase] == PurchasePhase.error.
  static final ValueNotifier<String?> errorMessage =
      ValueNotifier<String?>(null);

  /// Seed the entitlement from the persisted flag. Cheap (a prefs read);
  /// await this before the first frame so gated UI is immediately correct.
  static Future<void> seedPremium() async {
    isPremium.value = await PreferenceService.isPremium();
  }

  /// Start listening to the purchase stream so interrupted/pending
  /// transactions are delivered. Involves a platform availability check, so
  /// call it without blocking the first frame.
  static Future<void> startListening() async {
    if (_listening) return;
    _listening = true;

    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        phase.value = PurchasePhase.error;
        errorMessage.value = error.toString();
      },
    );
  }

  static Future<void> _onPurchaseUpdate(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          phase.value = PurchasePhase.pending;
          errorMessage.value = null;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(purchase);
          phase.value = PurchasePhase.idle;
          errorMessage.value = null;
          break;
        case PurchaseStatus.error:
          phase.value = PurchasePhase.error;
          errorMessage.value = purchase.error?.message ?? 'Purchase failed';
          break;
        case PurchaseStatus.canceled:
          phase.value = PurchasePhase.idle;
          errorMessage.value = null;
          break;
      }

      // Always finish the transaction so the store stops re-delivering it.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  static Future<void> _deliver(PurchaseDetails purchase) async {
    if (purchase.productID == AppStrings.premiumProductId) {
      await PreferenceService.setPremium(true);
      isPremium.value = true;
    }
  }

  /// Start purchasing premium (non-consumable). Resolution arrives via the
  /// stream; callers observe [phase] / [isPremium] for the outcome.
  static Future<void> purchasePremium() async {
    await startListening();
    phase.value = PurchasePhase.pending;
    errorMessage.value = null;
    try {
      final response =
          await _iap.queryProductDetails({AppStrings.premiumProductId});
      if (response.productDetails.isEmpty) {
        throw Exception('Product not found');
      }
      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      phase.value = PurchasePhase.error;
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  /// Restore previous purchases. Restored entitlements arrive via the stream.
  static Future<void> restorePurchases() async {
    await startListening();
    phase.value = PurchasePhase.pending;
    errorMessage.value = null;
    await _iap.restorePurchases();
    // Clear the spinner if nothing was delivered (e.g. nothing to restore).
    if (phase.value == PurchasePhase.pending) {
      phase.value = PurchasePhase.idle;
    }
  }

  /// Dispose the listener (rarely needed; the service lives for app lifetime).
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _listening = false;
  }
}
