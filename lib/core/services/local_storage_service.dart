// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Local Storage Service
// ═══════════════════════════════════════════════════════════════

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:my_first_app/core/services/logger_service.dart';

/// Local ma'lumotlarni saqlash va olish servisi.
///
/// 2 ta storage ishlatiladi:
/// 1. [Hive] — tez, oddiy ma'lumotlar uchun (cache, settings)
/// 2. [FlutterSecureStorage] — maxfiy ma'lumotlar uchun (token)
///
/// Bolaga tushuntirish:
/// Hive — cho'ntagingdagi daftar (tez yozasan, tez o'qiysan).
/// SecureStorage — seyfingdagi daftar (faqat sen ochasan).
class StorageService {
  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _secureStorage;

  // ═══════════════════════════════════
  // Hive Box nomlari
  // ═══════════════════════════════════
  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';

  // ═══════════════════════════════════
  // Secure Storage kalitlari
  // ═══════════════════════════════════
  static const String _keyOnboardingSeen = 'onboarding_seen';

  // ═══════════════════════════════════
  // 🔧 INITIALIZATION
  // ═══════════════════════════════════

  /// Hive box larni ochish (main.dart da chaqiriladi).
  Future<void> init() async {
    await Hive.openBox<dynamic>(_settingsBox);
    await Hive.openBox<dynamic>(_cacheBox);
    LoggerService.info('StorageService initialized');
  }

  // ═══════════════════════════════════
  // 📦 HIVE — TEZKOR SAQLASH
  // ═══════════════════════════════════

  /// Qiymat saqlash (Hive).
  Future<void> put(String key, dynamic value, {String? boxName}) async {
    final box = Hive.box<dynamic>(boxName ?? _settingsBox);
    await box.put(key, value);
  }

  /// Qiymat olish (Hive).
  T? get<T>(String key, {T? defaultValue, String? boxName}) {
    final box = Hive.box<dynamic>(boxName ?? _settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Qiymat o'chirish (Hive).
  Future<void> remove(String key, {String? boxName}) async {
    final box = Hive.box<dynamic>(boxName ?? _settingsBox);
    await box.delete(key);
  }

  /// Box ni tozalash.
  Future<void> clearBox({String? boxName}) async {
    final box = Hive.box<dynamic>(boxName ?? _cacheBox);
    await box.clear();
    LoggerService.info('Box cleared: ${boxName ?? _cacheBox}');
  }

  // ═══════════════════════════════════
  // 🔒 SECURE STORAGE — MAXFIY SAQLASH
  // ═══════════════════════════════════

  /// Maxfiy qiymat saqlash.
  Future<void> setSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Maxfiy qiymat olish.
  Future<String?> getSecure(String key) async {
    return _secureStorage.read(key: key);
  }

  /// Maxfiy qiymat o'chirish.
  Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Barcha maxfiy ma'lumotlarni tozalash (logout da).
  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
    LoggerService.info('Secure storage cleared');
  }

  /// Barcha maxfiy kalitlar nomini olish.
  /// Debug uchun — OpenAI kalit nomini aniqlashda ishlatiladi.
  Future<List<String>> getAllSecureKeys() async {
    try {
      final all = await _secureStorage.readAll();
      return all.keys.toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════
  // 📋 CONVENIENCE METHODS
  // ═══════════════════════════════════

  /// Onboarding ko'rilganmi?
  bool get isOnboardingSeen {
    return get<bool>(_keyOnboardingSeen, defaultValue: false) ?? false;
  }

  /// Onboarding ko'rildi deb belgilash.
  Future<void> setOnboardingSeen() async {
    await put(_keyOnboardingSeen, true);
  }

  // ═══════════════════════════════════
  // 💾 CACHE METHODS
  // ═══════════════════════════════════

  /// Cache ga JSON saqlash (String shaklida).
  Future<void> cacheData(String key, String jsonString) async {
    await put(key, jsonString, boxName: _cacheBox);
    await put(
      '${key}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
      boxName: _cacheBox,
    );
  }

  /// Cache dan JSON olish.
  /// [maxAge] — cache ning maksimal yoshi (default: 1 soat).
  String? getCachedData(
    String key, {
    Duration maxAge = const Duration(hours: 1),
  }) {
    final timestamp = get<int>('${key}_timestamp', boxName: _cacheBox);
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(cacheTime);

    if (age > maxAge) {
      // Cache eskirgan
      return null;
    }

    return get<String>(key, boxName: _cacheBox);
  }
}

// ═══════════════════════════════════
// RIVERPOD PROVIDER
// ═══════════════════════════════════

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
