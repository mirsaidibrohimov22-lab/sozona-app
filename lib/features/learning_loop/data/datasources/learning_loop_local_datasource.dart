// QO'YISH: lib/features/learning_loop/data/datasources/learning_loop_local_datasource.dart
// So'zona — Learning Loop Hive (offline) datasource

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/features/learning_loop/data/models/learner_profile_model.dart';
import 'package:my_first_app/features/learning_loop/data/models/weak_item_pool_model.dart';

abstract class LearningLoopLocalDataSource {
  Future<void> cacheWeakItems(String userId, List<WeakItemModel> items);
  Future<List<WeakItemModel>> getCachedWeakItems(String userId);
  Future<void> cacheLearnerProfile(LearnerProfileModel profile);
  Future<LearnerProfileModel?> getCachedLearnerProfile(String userId);
  Future<void> clearCache(String userId);
}

class LearningLoopLocalDataSourceImpl implements LearningLoopLocalDataSource {
  static const String _weakItemsBox = 'weak_items_box';
  static const String _profileBox = 'learner_profile_box';

  late Box<String> _weakItems;
  late Box<String> _profiles;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _weakItems = await Hive.openBox<String>(_weakItemsBox);
    _profiles = await Hive.openBox<String>(_profileBox);
    _initialized = true;
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }

  @override
  Future<void> cacheWeakItems(String userId, List<WeakItemModel> items) async {
    await _ensureInit();
    try {
      final jsonList = items.map((item) => item.toFirestore()).toList();
      await _weakItems.put(userId, jsonEncode(jsonList));
    } catch (e) {
      throw CacheException(message: 'Zaif elementlar saqlanmadi: $e');
    }
  }

  @override
  Future<List<WeakItemModel>> getCachedWeakItems(String userId) async {
    await _ensureInit();
    try {
      final jsonStr = _weakItems.get(userId);
      if (jsonStr == null) return [];

      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((map) {
        final m = map as Map<String, dynamic>;
        final id = m['id'] as String? ?? '';
        return WeakItemModel.fromMap(m, id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheLearnerProfile(LearnerProfileModel profile) async {
    await _ensureInit();
    try {
      await _profiles.put(profile.userId, jsonEncode(profile.toFirestore()));
    } catch (e) {
      throw CacheException(message: 'Profil saqlanmadi: $e');
    }
  }

  @override
  Future<LearnerProfileModel?> getCachedLearnerProfile(String userId) async {
    await _ensureInit();
    try {
      final jsonStr = _profiles.get(userId);
      if (jsonStr == null) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LearnerProfileModel.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCache(String userId) async {
    await _ensureInit();
    await _weakItems.delete(userId);
    await _profiles.delete(userId);
  }
}
