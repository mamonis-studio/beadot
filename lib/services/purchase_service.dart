import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants.dart';
import 'preference_service.dart';

class PurchaseService {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static bool _initialized = false;

  /// Initialize and listen for purchase updates.
  static Future<void> initialize() async {
    if (_initialized) return;
    final available = await _iap.isAvailable();
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );

    _initialized = true;
  }

  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _verifyAndDeliver(purchase);
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  static Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    if (purchase.productID == AppStrings.premiumProductId) {
      await PreferenceService.setPremium(true);
    }
  }

  /// Purchase premium (non-consumable).
  static Future<void> purchasePremium() async {
    await initialize();

    final response = await _iap.queryProductDetails({AppStrings.premiumProductId});
    if (response.productDetails.isEmpty) {
      throw Exception('Product not found');
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases.
  static Future<void> restorePurchases() async {
    await initialize();
    await _iap.restorePurchases();
  }

  /// Dispose listener.
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
