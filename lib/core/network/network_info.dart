// lib/core/network/network_info.dart
// So'zona — Internet aloqasi tekshiruvchi
// Offline-first arxitektura uchun kerak

import 'package:connectivity_plus/connectivity_plus.dart';

/// Internet aloqasi interfeysi
abstract class NetworkInfo {
  /// Internet bormi?
  Future<bool> get isConnected;

  /// Aloqa holatini kuzatish (stream)
  Stream<bool> get onConnectivityChanged;
}

/// Connectivity Plus orqali implementatsiya
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl({required Connectivity connectivity})
      : _connectivity = connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return !results.contains(ConnectivityResult.none);
    });
  }
}
