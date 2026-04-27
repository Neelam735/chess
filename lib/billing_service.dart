import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Wraps Google Play Billing for the chess app's single non-consumable
/// "premium" upgrade. Listens to the global purchase stream, exposes a
/// [ValueNotifier] that any screen can rebuild against, and handles
/// purchase, restore and verification calls.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  /// Product ID configured in Google Play Console / App Store Connect.
  static const String premiumProductId = 'chess_premium_unlock';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Whether the billing platform is available on this device.
  final ValueNotifier<bool> available = ValueNotifier<bool>(false);

  /// Resolved product details (null until [init] succeeds).
  final ValueNotifier<ProductDetails?> product = ValueNotifier<ProductDetails?>(null);

  /// Whether the user has unlocked the premium upgrade.
  final ValueNotifier<bool> isPremium = ValueNotifier<bool>(false);

  /// Whether a purchase is currently in flight.
  final ValueNotifier<bool> isPurchasing = ValueNotifier<bool>(false);

  Future<void> init() async {
    available.value = await _iap.isAvailable();
    if (!available.value) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => debugPrint('purchaseStream error: $e'),
    );

    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.productDetails.isNotEmpty) {
      product.value = response.productDetails.first;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Kicks off the Play Billing purchase flow for the premium upgrade.
  Future<void> buyPremium() async {
    final p = product.value;
    if (p == null || isPurchasing.value) return;
    isPurchasing.value = true;
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: p),
      );
    } catch (e) {
      debugPrint('buyNonConsumable failed: $e');
      isPurchasing.value = false;
    }
  }

  /// Restores any previously completed purchases.
  Future<void> restorePurchases() => _iap.restorePurchases();

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == premiumProductId) {
            isPremium.value = true;
          }
          isPurchasing.value = false;
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          isPurchasing.value = false;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }
}
