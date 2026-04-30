// lib/features/premium/presentation/providers/iap_provider.dart
// So'zona — IAP Provider
// ✅ FIX 1: checkAuthStatus() → refreshUserFromServer()
//    Sabab: checkAuthStatus() Firestore cache'dan o'qiydi → isPremium false qoladi
//    refreshUserFromServer() forceServer:true bilan serverdan yangilaydi → hasPremiumProvider to'g'ri ishlaydi

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/data/services/iap_service.dart';

enum IAPStatus { idle, loading, success, error }

class IAPState {
  final IAPStatus status;
  final String? errorMessage;
  final String? successProductId;
  final bool isAvailable;

  const IAPState({
    this.status = IAPStatus.idle,
    this.errorMessage,
    this.successProductId,
    this.isAvailable = false,
  });

  IAPState copyWith({
    IAPStatus? status,
    String? errorMessage,
    String? successProductId,
    bool? isAvailable,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return IAPState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successProductId:
          clearSuccess ? null : (successProductId ?? this.successProductId),
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class IAPNotifier extends StateNotifier<IAPState> {
  final IAPService _service;
  final Ref _ref;

  IAPNotifier(this._service, this._ref) : super(const IAPState()) {
    _init();
  }

  Future<void> _init() async {
    await _service.initialize();

    _service.onPurchaseSuccess = (productId) async {
      // verifyPurchase Cloud Function allaqachon Firestore ga yozadi —
      // client-side yozish shart emas. Server dan yangilash yetarli.
      if (!mounted) return;
      await _ref.read(authNotifierProvider.notifier).refreshUserFromServer();

      if (!mounted) return;
      state = state.copyWith(
          status: IAPStatus.success, successProductId: productId);
    };

    _service.onPurchaseError = (error) {
      if (!mounted) return;
      state = state.copyWith(status: IAPStatus.error, errorMessage: error);
    };

    _service.onPurchasePending = () {
      if (!mounted) return;
      state = state.copyWith(status: IAPStatus.loading);
    };

    if (!mounted) return;
    state = state.copyWith(isAvailable: _service.isAvailable);
  }

  Future<void> buyMonthly() async {
    state = state.copyWith(status: IAPStatus.loading, clearError: true);
    await _service.buyProduct(IAPProducts.monthly);
  }

  Future<void> buyYearly() async {
    state = state.copyWith(status: IAPStatus.loading, clearError: true);
    await _service.buyProduct(IAPProducts.yearly);
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(status: IAPStatus.loading, clearError: true);
    await _service.restorePurchases();
  }

  String get monthlyPrice => _service.getPrice(IAPProducts.monthly) ?? '\$4.99';
  String get yearlyPrice => _service.getPrice(IAPProducts.yearly) ?? '\$29.99';

  void clearStatus() {
    state = state.copyWith(
        status: IAPStatus.idle, clearError: true, clearSuccess: true);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService();
  ref.onDispose(() => service.dispose());
  return service;
});

final iapProvider = StateNotifierProvider<IAPNotifier, IAPState>((ref) {
  return IAPNotifier(ref.watch(iapServiceProvider), ref);
});
