import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps Google Play Billing for the chess app's single non-consumable
/// "premium" upgrade. Listens to the global purchase stream, exposes a
/// [ValueNotifier] that any screen can rebuild against, and handles
/// purchase, restore and verification calls.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  /// Product ID configured in Google Play Console / App Store Connect.
  static const String premiumProductId = 'chess_premium_unlock';

  /// SharedPreferences key for the debug-only "force premium" flag.
  static const String _kDebugPremiumKey = 'debug_premium_override';

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

  /// Last billing event surfaced for QA / debugging. Mirrors what gets
  /// logged via [debugPrint] but lets us also render it on screen.
  final ValueNotifier<String?> lastEvent = ValueNotifier<String?>(null);

  void _log(String message) {
    debugPrint('[Billing] $message');
    lastEvent.value = message;
  }

  Future<void> init() async {
    // Apply any debug-only premium override before touching the store, so
    // gated UI is correct even on emulators / dev builds where billing
    // isn't reachable.
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kDebugPremiumKey) ?? false) {
        isPremium.value = true;
        _log('debug override → premium ON');
      }
    }

    available.value = await _iap.isAvailable();
    _log('Play Billing available=${available.value}');
    if (!available.value) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (Object e) => _log('purchaseStream error: $e'),
    );

    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.error != null) {
      _log('queryProductDetails error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      _log('product not found in store: ${response.notFoundIDs}');
    }
    if (response.productDetails.isNotEmpty) {
      product.value = response.productDetails.first;
      _log('product resolved: ${product.value!.id} @ ${product.value!.price}');
    }

    // Re-check ownership on every cold start so previously paying users
    // aren't asked to pay again.
    try {
      await _iap.restorePurchases();
      _log('restorePurchases requested');
    } catch (e) {
      _log('restorePurchases failed: $e');
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Kicks off the Play Billing purchase flow for the premium upgrade.
  Future<void> buyPremium() async {
    final p = product.value;
    if (p == null) {
      _log('buyPremium aborted: product not loaded');
      return;
    }
    if (isPurchasing.value) {
      _log('buyPremium ignored: another purchase already in flight');
      return;
    }
    isPurchasing.value = true;
    _log('launching Play Billing for ${p.id}');
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: p),
      );
    } catch (e) {
      _log('buyNonConsumable failed: $e');
      isPurchasing.value = false;
    }
  }

  /// Restores any previously completed purchases.
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Debug-only: flip the premium flag and persist it across launches.
  /// No-op outside of debug builds so the override can never ship.
  Future<bool> togglePremiumDebug() async {
    if (!kDebugMode) return isPremium.value;
    final prefs = await SharedPreferences.getInstance();
    final next = !isPremium.value;
    await prefs.setBool(_kDebugPremiumKey, next);
    isPremium.value = next;
    return next;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          isPurchasing.value = true;
          _log('purchase pending (${purchase.productID})');
          break;
        case PurchaseStatus.purchased:
          if (purchase.productID == premiumProductId) {
            isPremium.value = true;
            _log('PURCHASED ${purchase.productID} → premium ON');
          }
          isPurchasing.value = false;
          break;
        case PurchaseStatus.restored:
          if (purchase.productID == premiumProductId) {
            isPremium.value = true;
            _log('restored ${purchase.productID} → premium ON');
          }
          isPurchasing.value = false;
          break;
        case PurchaseStatus.error:
          // Play returns ITEM_ALREADY_OWNED (Billing response code 7) when
          // a non-consumable was bought before but the local entitlement
          // was lost. Treat it as success so the user is unblocked.
          final msg = purchase.error?.message ?? '';
          final isAlreadyOwned = msg.toLowerCase().contains('already owned') ||
              (purchase.error?.code ?? '') == 'BillingResponse.itemAlreadyOwned';
          if (isAlreadyOwned && purchase.productID == premiumProductId) {
            isPremium.value = true;
            _log('error ITEM_ALREADY_OWNED → granting premium');
          } else {
            _log('purchase error: ${purchase.error}');
          }
          isPurchasing.value = false;
          break;
        case PurchaseStatus.canceled:
          _log('purchase canceled by user');
          isPurchasing.value = false;
          break;
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
        _log('completePurchase acknowledged');
      }
    }
  }
}
