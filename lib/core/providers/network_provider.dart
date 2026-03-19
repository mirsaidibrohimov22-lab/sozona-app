// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Network Providers
// QO'YISH: lib/core/providers/network_provider.dart
// ═══════════════════════════════════════════════════════════════
//
// Bu fayl — Network bilan bog'liq providerlar.
// Internet mavjudligini tekshirish uchun.
//
// Bolaga tushuntirish:
// Bu — WiFi indikatori. Internet bormi yo'qmi — shu yerdan bilib olasiz.
// ═══════════════════════════════════════════════════════════════

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:my_first_app/core/network/network_info.dart';

// ═══════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════

/// Internet Connection Checker Provider
final internetConnectionCheckerProvider = Provider<InternetConnection>((ref) {
  return InternetConnection();
});

/// Network Info Provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(connectivity: Connectivity());
});

/// Network Status Stream Provider — real-time internet holati
final networkStatusProvider = StreamProvider<InternetStatus>((ref) {
  final connectionChecker = ref.watch(internetConnectionCheckerProvider);
  return connectionChecker.onStatusChange;
});

/// Is Connected Provider — hozir internet bormi?
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final networkInfo = ref.watch(networkInfoProvider);
  return await networkInfo.isConnected;
});
