// QO'YISH: lib/core/providers/network_provider.dart
// So'zona — Internet aloqasi provider'i

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/network/network_info.dart';

/// Connectivity singleton
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// NetworkInfo provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(
    connectivity: ref.watch(connectivityProvider),
  );
});
