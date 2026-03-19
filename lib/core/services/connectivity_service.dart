// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Connectivity Service
// ═══════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:my_first_app/core/services/logger_service.dart';

/// Internet ulanishini real-time kuzatish servisi.
///
/// 2 bosqichli tekshiruv:
/// 1. [Connectivity] — WiFi/Mobile/None (tezkor, lekin ishonchsiz)
/// 2. [InternetConnection] — haqiqiy internet bormi (ping orqali)
///
/// Bolaga tushuntirish:
/// Telefoningda WiFi belgisi bor — lekin internet ishlamasligi mumkin.
/// Shuning uchun ikki marta tekshiramiz: avval WiFi bormi, keyin internet bormi.
class ConnectivityService {
  ConnectivityService({
    Connectivity? connectivity,
    InternetConnection? internetConnection,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetConnection = internetConnection ?? InternetConnection();

  final Connectivity _connectivity;
  final InternetConnection _internetConnection;

  /// Hozir internet bormi?
  ///
  /// Bitta marta tekshirish uchun. UI da "Yuklash" tugmasidan oldin ishlatiladi.
  /// ```dart
  /// if (await connectivityService.hasConnection) {
  ///   // Online — serverdan olamiz
  /// } else {
  ///   // Offline — cache dan olamiz
  /// }
  /// ```
  Future<bool> get hasConnection async {
    final connectivityResult = await _connectivity.checkConnectivity();

    // Hech qanday ulanish yo'q
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    // WiFi/Mobile bor — lekin haqiqiy internet bormi?
    final hasInternet = await _internetConnection.hasInternetAccess;
    return hasInternet;
  }

  /// Internet holatini real-time kuzatish (stream).
  ///
  /// UI da OfflineBanner ko'rsatish uchun ishlatiladi.
  /// ```dart
  /// ref.watch(connectivityStreamProvider).when(
  ///   data: (isOnline) => isOnline ? hideOfflineBanner() : showOfflineBanner(),
  /// );
  /// ```
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      if (results.contains(ConnectivityResult.none)) {
        LoggerService.info('Connectivity: OFFLINE');
        return false;
      }

      final hasInternet = await _internetConnection.hasInternetAccess;
      LoggerService.info(
        'Connectivity: ${hasInternet ? "ONLINE" : "NO INTERNET"}',
      );
      return hasInternet;
    });
  }
}

// ═══════════════════════════════════
// RIVERPOD PROVIDERS
// ═══════════════════════════════════

/// [ConnectivityService] instance provider.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Internet holatini real-time kuzatish provider.
///
/// Har qanday widget da internet holatini kuzatish uchun:
/// ```dart
/// final isOnline = ref.watch(connectivityStreamProvider);
/// ```
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
