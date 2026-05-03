// lib/features/premium/data/services/iap_service.dart
// So'zona — Google Play In-App Purchase Service
// ✅ Oylik va yillik obuna
// ✅ Xarid tasdiqlash
// ✅ Mavjud obunani tiklash

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ═══════════════════════════════════════════════════════════════
// MAHSULOT ID LARI — Play Console dagi ID lar bilan mos kelishi kerak
// ═══════════════════════════════════════════════════════════════
class IAPProducts {
  static const String monthly = 'sozana_premium_monthly';
  static const String yearly = 'sozona_premium_yearly';
  static const Set<String> all = {monthly, yearly};
}

// ═══════════════════════════════════════════════════════════════
// IAP SERVICE
// ═══════════════════════════════════════════════════════════════
class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Mahsulotlar
  List<ProductDetails> products = [];
  bool isAvailable = false;

  // Callbacks
  Function(String productId)? onPurchaseSuccess;
  Function(String error)? onPurchaseError;
  Function()? onPurchasePending;

  // ── INITIALIZE ───────────────────────────────────────────────
  Future<void> initialize() async {
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      debugPrint('⚠️ IAP: Google Play mavjud emas');
      return;
    }

    // Purchase stream ni tinglash
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        debugPrint('⚠️ IAP Stream xatosi: $error');
      },
    );

    // Mahsulotlarni yuklash
    await _loadProducts();
  }

  // ── MAHSULOTLARNI YUKLASH ────────────────────────────────────
  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(IAPProducts.all);
      if (response.error != null) {
        debugPrint('⚠️ Mahsulot yuklash xatosi: ${response.error}');
        return;
      }
      products = response.productDetails;
      debugPrint('✅ IAP: ${products.length} ta mahsulot yuklandi');
    } catch (e) {
      debugPrint('⚠️ IAP yuklash xatosi: $e');
    }
  }

  // ── SOTIB OLISH ──────────────────────────────────────────────
  Future<void> buyProduct(String productId) async {
    if (!isAvailable) {
      onPurchaseError?.call('Google Play mavjud emas');
      return;
    }

    final product = products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      onPurchaseError?.call('Mahsulot topilmadi: $productId');
      return;
    }

    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      onPurchaseError?.call('Xarid xatosi: $e');
    }
  }

  // ── MAVJUD OBUNANI TIKLASH ───────────────────────────────────
  Future<void> restorePurchases() async {
    if (!isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      onPurchaseError?.call('Tiklash xatosi: $e');
    }
  }

  // ── XARID HOLATI KUZATISH ────────────────────────────────────
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          onPurchasePending?.call();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Cloud Function orqali tasdiqlash
          final verified = await _verifyPurchase(purchase);
          if (verified) {
            await _iap.completePurchase(purchase);
            onPurchaseSuccess?.call(purchase.productID);
          } else {
            onPurchaseError?.call('Xarid tasdiqlanmadi');
          }
          break;

        case PurchaseStatus.error:
          onPurchaseError?.call(
            purchase.error?.message ?? 'Noma\'lum xato',
          );
          await _iap.completePurchase(purchase);
          break;

        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  // ── CLOUD FUNCTION ORQALI TASDIQLASH ────────────────────────
  // ✅ FIX: package name endi dinamik olinadi
  // Avval: 'com.example.sozona' — test nomi, haqiqiy Play da ishlamaydi
  // Yangi: PackageInfo.fromPlatform() — qurilmadan haqiqiy nomni oladi
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      // Haqiqiy package name ni qurilmadan olish
      final packageInfo = await PackageInfo.fromPlatform();
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('verifyPurchase');
      final result = await callable.call({
        'productId': purchase.productID,
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'packageName': packageInfo.packageName, // ✅ dinamik, to'g'ri nom
      });
      return result.data['verified'] as bool? ?? false;
    } catch (e) {
      debugPrint('⚠️ Tasdiqlash xatosi: $e');
      // Xato bo'lsa — xarid tasdiqlanmaydi (xavfsizlik uchun)
      return false;
    }
  }

  // ── MAHSULOT NARXINI OLISH ───────────────────────────────────
  String? getPrice(String productId) {
    return products.where((p) => p.id == productId).firstOrNull?.price;
  }

  // ── DISPOSE ──────────────────────────────────────────────────
  void dispose() {
    _subscription?.cancel();
  }
}
