// lib/core/services/offline_activity_queue.dart
// So'zona — Offline Activity Queue
// Foydalanuvchi internetsiz dars qilsa, natijalar shu yerga saqlanadi.
// Internet qaytganda ActivitySyncService avtomatik serverga yuboradi.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineActivityQueue {
  OfflineActivityQueue._();
  static const _key = 'offline_activity_queue';

  /// Offline faoliyatni navbatga qo'shish
  static Future<void> add(Map<String, dynamic> activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      final List<dynamic> list = raw != null ? jsonDecode(raw) : [];

      // Vaqtni qo'shib saqlaymiz — sync paytida tartib uchun
      final entry = {
        ...activity,
        '_queuedAt': DateTime.now().toIso8601String(),
      };
      list.add(entry);

      await prefs.setString(_key, jsonEncode(list));
      debugPrint('📥 Offline queue: ${list.length} ta faoliyat saqlandi');
    } catch (e) {
      debugPrint('⚠️ Offline queue ga yozish xatosi: $e');
    }
  }

  /// Navbatdagi barcha faoliyatlarni olish
  static Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('⚠️ Offline queue o\'qish xatosi: $e');
      return [];
    }
  }

  /// Muvaffaqiyatli sync dan keyin navbatni tozalash
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      debugPrint('✅ Offline queue tozalandi');
    } catch (e) {
      debugPrint('⚠️ Offline queue tozalash xatosi: $e');
    }
  }

  /// Navbat bo'shmi?
  static Future<bool> isEmpty() async {
    final list = await getAll();
    return list.isEmpty;
  }

  /// Navbatdagi faoliyatlar soni
  static Future<int> count() async {
    final list = await getAll();
    return list.length;
  }
}
