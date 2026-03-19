// QO'YISH: lib/features/student/quiz/data/datasources/quiz_local_datasource.dart
// So'zona — Quiz Hive offline cache

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/core/error/exceptions.dart';

abstract class QuizLocalDataSource {
  Future<void> cacheQuizIds(String userId, List<String> ids);
  Future<List<String>> getCachedQuizIds(String userId);
  Future<void> cacheQuizJson(String quizId, Map<String, dynamic> json);
  Future<Map<String, dynamic>?> getCachedQuizJson(String quizId);
}

class QuizLocalDataSourceImpl implements QuizLocalDataSource {
  static const String _idsBox = 'quiz_ids_box';
  static const String _dataBox = 'quiz_data_box';
  late Box<String> _ids;
  late Box<String> _data;
  bool _init = false;

  Future<void> _ensure() async {
    if (_init) return;
    _ids = await Hive.openBox<String>(_idsBox);
    _data = await Hive.openBox<String>(_dataBox);
    _init = true;
  }

  @override
  Future<void> cacheQuizIds(String userId, List<String> ids) async {
    await _ensure();
    try {
      await _ids.put(userId, jsonEncode(ids));
    } catch (e) {
      throw CacheException(message: 'Quiz IDlar saqlanmadi: $e');
    }
  }

  @override
  Future<List<String>> getCachedQuizIds(String userId) async {
    await _ensure();
    try {
      final s = _ids.get(userId);
      if (s == null) return [];
      return List<String>.from(jsonDecode(s) as List);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheQuizJson(String quizId, Map<String, dynamic> json) async {
    await _ensure();
    try {
      await _data.put(quizId, jsonEncode(json));
    } catch (e) {
      throw CacheException(message: 'Quiz saqlanmadi: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getCachedQuizJson(String quizId) async {
    await _ensure();
    try {
      final s = _data.get(quizId);
      if (s == null) return null;
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
