// lib/core/providers/core_providers.dart
// So'zona — Core Riverpod providerlari

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/services/analytics_service.dart';
import 'package:my_first_app/core/services/local_storage_service.dart';
import 'package:my_first_app/core/services/remote_config_service.dart';
import 'package:my_first_app/core/services/tts_service.dart';
import 'package:my_first_app/core/utils/debouncer.dart';

// Storage
// ✅ K2 FIX: storageServiceProvider ga alias — bitta instance, ikkinchi yaratilmaydi
final localStorageServiceProvider = storageServiceProvider;

// Remote Config
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

// Analytics
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Debouncer (search va boshqa input uchun)
final debouncerProvider = Provider.family<Debouncer, Duration>((ref, delay) {
  final debouncer = Debouncer(delay: delay);
  ref.onDispose(debouncer.dispose);
  return debouncer;
});

// TTS
final ttsInitProvider = FutureProvider<void>((ref) async {
  await TtsService.init();
});
