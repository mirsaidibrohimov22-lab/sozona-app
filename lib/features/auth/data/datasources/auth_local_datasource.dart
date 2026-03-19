// lib/features/auth/data/datasources/auth_local_datasource.dart
// So'zona — Auth Local DataSource
// Foydalanuvchi ma'lumotlarini mahalliy saqlash (offline qo'llab-quvvatlash)

import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/auth/data/models/user_model.dart';

/// Local datasource interfeysi
abstract class AuthLocalDataSource {
  /// Foydalanuvchi ma'lumotlarini cache'ga saqlash
  Future<void> cacheUser(UserModel user);

  /// Cache'dan foydalanuvchi olish
  Future<UserModel?> getCachedUser();

  /// Cache'ni tozalash (chiqishda)
  Future<void> clearCache();

  /// Birinchi marta ochilganligini tekshirish (onboarding uchun)
  Future<bool> isFirstLaunch();

  /// Birinchi ochilish flagini o'rnatish
  Future<void> setFirstLaunchComplete();

  /// Onboarding ko'rsatilganmi
  Future<bool> isOnboardingComplete();

  /// Onboarding tugadi flagini o'rnatish
  Future<void> setOnboardingComplete();
}

/// SharedPreferences implementatsiyasi
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;
  final Logger _logger;

  /// Cache kalitlari
  static const String _cachedUserKey = 'CACHED_USER';
  static const String _firstLaunchKey = 'IS_FIRST_LAUNCH';
  static const String _onboardingCompleteKey = 'ONBOARDING_COMPLETE';

  AuthLocalDataSourceImpl({
    required SharedPreferences prefs,
    required Logger logger,
  })  : _prefs = prefs,
        _logger = logger;

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      _logger.d('Foydalanuvchi cache\'ga saqlanmoqda: ${user.id}');
      final jsonString = json.encode(user.toLocalMap());
      await _prefs.setString(_cachedUserKey, jsonString);
      _logger.d('Foydalanuvchi cache\'ga saqlandi');
    } catch (e) {
      _logger.e('Cache saqlash xatoligi: $e');
      throw const CacheException(
        message: 'Foydalanuvchi ma\'lumotlarini saqlashda xatolik',
      );
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = _prefs.getString(_cachedUserKey);

      if (jsonString == null) {
        _logger.d('Cache\'da foydalanuvchi yo\'q');
        return null;
      }

      _logger.d('Cache\'dan foydalanuvchi topildi');
      final map = json.decode(jsonString) as Map<String, dynamic>;
      return UserModel.fromLocalMap(map);
    } catch (e) {
      _logger.e('Cache o\'qish xatoligi: $e');
      // Cache buzilgan bo'lsa, tozalash
      await _prefs.remove(_cachedUserKey);
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      _logger.d('Auth cache tozalanmoqda');
      await _prefs.remove(_cachedUserKey);
      _logger.d('Auth cache tozalandi');
    } catch (e) {
      _logger.e('Cache tozalash xatoligi: $e');
      throw const CacheException(
        message: 'Cache tozalashda xatolik',
      );
    }
  }

  @override
  Future<bool> isFirstLaunch() async {
    // Kalit yo'q bo'lsa — birinchi marta ochilgan
    return !_prefs.containsKey(_firstLaunchKey);
  }

  @override
  Future<void> setFirstLaunchComplete() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  @override
  Future<bool> isOnboardingComplete() async {
    return _prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  @override
  Future<void> setOnboardingComplete() async {
    await _prefs.setBool(_onboardingCompleteKey, true);
  }
}
