// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Listening Local DataSource
// QO'YISH: lib/features/student/listening/data/datasources/listening_local_datasource.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/student/listening/data/models/listening_model.dart';

/// Listening Local DataSource — Offline cache
abstract class ListeningLocalDataSource {
  Future<void> cacheExercise(ListeningModel exercise);
  Future<List<ListeningModel>> getCachedExercises();
  Future<void> clearCache();
}

class ListeningLocalDataSourceImpl implements ListeningLocalDataSource {
  static const String boxName = 'listening_cache';
  static const String exercisesKey = 'cached_exercises';

  @override
  Future<void> cacheExercise(ListeningModel exercise) async {
    try {
      final box = await Hive.openBox(boxName);

      // Mavjud cache'ni olish
      final cachedJson = box.get(exercisesKey, defaultValue: '[]') as String;
      final List<dynamic> cached = jsonDecode(cachedJson);

      // Yangi exercise qo'shish (agar mavjud bo'lsa - yangilash)
      cached.removeWhere((e) => e['id'] == exercise.id);
      cached.insert(0, exercise.toJson());

      // Maksimal 10 ta saqlash
      if (cached.length > 10) {
        cached.removeRange(10, cached.length);
      }

      await box.put(exercisesKey, jsonEncode(cached));
    } catch (e) {
      throw CacheException(message: 'Failed to cache exercise: $e');
    }
  }

  @override
  Future<List<ListeningModel>> getCachedExercises() async {
    try {
      final box = await Hive.openBox(boxName);
      final cachedJson = box.get(exercisesKey, defaultValue: '[]') as String;
      final List<dynamic> cached = jsonDecode(cachedJson);

      return cached
          .map((json) => ListeningModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached exercises: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox(boxName);
      await box.delete(exercisesKey);
    } catch (e) {
      throw CacheException(message: 'Failed to clear cache: $e');
    }
  }
}
