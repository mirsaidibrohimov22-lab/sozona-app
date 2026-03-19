// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Remote Config Service
// ═══════════════════════════════════════════════════════════════

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/services/logger_service.dart';

/// Firebase Remote Config — serverdan turib ilovani boshqarish.
///
/// Bolaga tushuntirish:
/// O'qituvchi sinfda qoidalarni o'zgartiradi — hamma darrov biladi.
/// Remote Config ham shunday — Firebase Console dan flagni o'zgartirsang,
/// ilova yangilanmasdan o'zgarish ko'rinadi.
class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  // ═══════════════════════════════════
  // FEATURE FLAG NOMLARI
  // ═══════════════════════════════════
  static const String keyStudentQuizAddEnabled = 'student_quiz_add_enabled';
  static const String keyPremiumTtsEnabled = 'premium_tts_enabled';
  static const String keyMicroSessionEnabled = 'micro_session_enabled';
  static const String keyArtikelModuleEnabled = 'artikel_module_enabled';
  static const String keyAiChatEnabled = 'ai_chat_enabled';
  static const String keySpeakingEnabled = 'speaking_enabled';
  static const String keyMaxFreeAiRequests = 'max_free_ai_requests';
  static const String keyMaintenanceMode = 'maintenance_mode';
  static const String keyMinAppVersion = 'min_app_version';

  /// Remote Config ni ishga tushirish.
  Future<void> init() async {
    // Default qiymatlar — agar serverdan kelmasam shu ishlatiladi
    await _remoteConfig.setDefaults({
      keyStudentQuizAddEnabled: true,
      keyPremiumTtsEnabled: false,
      keyMicroSessionEnabled: true,
      keyArtikelModuleEnabled: true,
      keyAiChatEnabled: true,
      keySpeakingEnabled: true,
      keyMaxFreeAiRequests: 100,
      keyMaintenanceMode: false,
      keyMinAppVersion: '1.0.0',
    });

    // Fetch sozlamalari
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Serverdan olish
    try {
      await _remoteConfig.fetchAndActivate();
      LoggerService.info('RemoteConfig fetched and activated');
    } catch (e) {
      LoggerService.warning('RemoteConfig fetch failed: $e (using defaults)');
    }
  }

  // ═══════════════════════════════════
  // 📖 GETTERS
  // ═══════════════════════════════════

  /// Student o'zi quiz yarata oladimi?
  bool get isStudentQuizAddEnabled {
    return _remoteConfig.getBool(keyStudentQuizAddEnabled);
  }

  /// Premium TTS (Google Cloud) yoqilganmi?
  bool get isPremiumTtsEnabled {
    return _remoteConfig.getBool(keyPremiumTtsEnabled);
  }

  /// Mikro-sessiyalar yoqilganmi?
  bool get isMicroSessionEnabled {
    return _remoteConfig.getBool(keyMicroSessionEnabled);
  }

  /// Artikel moduli yoqilganmi?
  bool get isArtikelModuleEnabled {
    return _remoteConfig.getBool(keyArtikelModuleEnabled);
  }

  /// AI Chat yoqilganmi?
  bool get isAiChatEnabled {
    return _remoteConfig.getBool(keyAiChatEnabled);
  }

  /// Speaking moduli yoqilganmi?
  bool get isSpeakingEnabled {
    return _remoteConfig.getBool(keySpeakingEnabled);
  }

  /// Bepul AI so'rovlar limiti.
  int get maxFreeAiRequests {
    return _remoteConfig.getInt(keyMaxFreeAiRequests);
  }

  /// Texnik ishlar rejimimi?
  bool get isMaintenanceMode {
    return _remoteConfig.getBool(keyMaintenanceMode);
  }

  /// Minimal ilova versiyasi.
  String get minAppVersion {
    return _remoteConfig.getString(keyMinAppVersion);
  }

  /// Umumiy bool flag olish.
  bool getBool(String key) => _remoteConfig.getBool(key);

  /// Umumiy string flag olish.
  String getString(String key) => _remoteConfig.getString(key);

  /// Umumiy int flag olish.
  int getInt(String key) => _remoteConfig.getInt(key);
}

// ═══════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});
