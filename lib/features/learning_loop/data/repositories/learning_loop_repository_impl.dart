// QO'YISH: lib/features/learning_loop/data/repositories/learning_loop_repository_impl.dart
// So'zona — Learning Loop Repository implementatsiyasi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/network/network_info.dart';
import 'package:my_first_app/features/learning_loop/data/datasources/learning_loop_local_datasource.dart';
import 'package:my_first_app/features/learning_loop/data/datasources/learning_loop_remote_datasource.dart';
import 'package:my_first_app/features/learning_loop/data/models/learner_profile_model.dart';
import 'package:my_first_app/features/learning_loop/data/models/weak_item_pool_model.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/learner_profile.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/micro_session.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/learning_loop/domain/repositories/learning_loop_repository.dart';

class LearningLoopRepositoryImpl implements LearningLoopRepository {
  final LearningLoopRemoteDataSource _remote;
  final LearningLoopLocalDataSource _local;
  final NetworkInfo _networkInfo;

  LearningLoopRepositoryImpl({
    required LearningLoopRemoteDataSource remote,
    required LearningLoopLocalDataSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo;

  // ─── Weak Items ───

  @override
  Future<Either<Failure, List<WeakItem>>> getWeakItems(String userId) async {
    if (await _networkInfo.isConnected) {
      try {
        final items = await _remote.getWeakItems(userId);
        await _local.cacheWeakItems(userId, items);
        return Right(items);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final cached = await _local.getCachedWeakItems(userId);
        return Right(cached);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, List<WeakItem>>> getDueWeakItems(String userId) async {
    if (await _networkInfo.isConnected) {
      try {
        final items = await _remote.getDueWeakItems(userId);
        return Right(items);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      // Offline: cached elementlardan due bo'lganlarini filter qilamiz
      try {
        final cached = await _local.getCachedWeakItems(userId);
        final due = cached.where((item) => item.isDueForReview).toList();
        return Right(due);
      } catch (_) {
        return const Right([]);
      }
    }
  }

  @override
  Future<Either<Failure, WeakItem>> addWeakItem({
    required String userId,
    required WeakItemSource sourceType,
    required String sourceContentId,
    required String itemType,
    required WeakItemData itemData,
  }) async {
    try {
      final item = await _remote.addWeakItem(
        userId: userId,
        sourceType: sourceType,
        sourceContentId: sourceContentId,
        itemType: itemType,
        itemData: itemData,
      );
      return Right(item);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, WeakItem>> updateWeakItem(WeakItem item) async {
    try {
      final model = WeakItemModel.fromEntity(item);
      final updated = await _remote.updateWeakItem(model);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<WeakItem>>> batchUpdateWeakItems(
    List<WeakItem> items,
  ) async {
    try {
      final models = items.map(WeakItemModel.fromEntity).toList();
      final updated = await _remote.batchUpdateWeakItems(models);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── Learner Profile ───

  @override
  Future<Either<Failure, LearnerProfile>> getLearnerProfile(
    String userId,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final profile = await _remote.getLearnerProfile(userId);
        await _local.cacheLearnerProfile(profile);
        return Right(profile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final cached = await _local.getCachedLearnerProfile(userId);
        if (cached != null) return Right(cached);
        return Right(LearnerProfileModel.initial(userId));
      } catch (_) {
        return Right(LearnerProfileModel.initial(userId));
      }
    }
  }

  @override
  Future<Either<Failure, LearnerProfile>> updateLearnerProfile(
    LearnerProfile profile,
  ) async {
    try {
      final model = LearnerProfileModel.fromEntity(profile);
      final updated = await _remote.updateLearnerProfile(model);
      await _local.cacheLearnerProfile(updated);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, LearnerProfile>> analyzeAndUpdateProfile({
    required String userId,
    required String language,
    required String level,
  }) async {
    try {
      final profile = await _remote.analyzeAndUpdateProfile(
        userId: userId,
        language: language,
        level: level,
      );
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── Micro Sessions ───

  @override
  Future<Either<Failure, MicroSession>> getOrCreateNextSession(
    String userId,
  ) async {
    try {
      final session = await _remote.getOrCreateNextSession(userId);
      return Right(session);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, MicroSession>> startSession(String sessionId) async {
    // userId ni sessionId dan olish mumkin emas — provider dan uzatiladi
    // Bu yerda faqat remote chaqiramiz
    try {
      // userId ni alohida metodga qo'shamiz — hozircha placeholder
      throw const ServerException(message: 'startSession userId kerak');
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  /// userId bilan birga
  Future<Either<Failure, MicroSession>> startSessionWithUser(
    String sessionId,
    String userId,
  ) async {
    try {
      final session = await _remote.startSession(sessionId, userId);
      return Right(session);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, MicroSession>> completeSession({
    required String sessionId,
    required int overallScore,
    required int weakItemsReviewed,
    required int newWeakItems,
    required int xpEarned,
    String? motivationMessage,
  }) async {
    try {
      // userId provider dan keladi — bu yerda dummy ishlatamiz
      // Real implementatsiyada provider userId ni uzatadi
      throw const ServerException(
        message: 'completeSession userId kerak — provider orqali chaqiring',
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  /// userId bilan birga
  Future<Either<Failure, MicroSession>> completeSessionWithUser({
    required String sessionId,
    required String userId,
    required int overallScore,
    required int weakItemsReviewed,
    required int newWeakItems,
    required int xpEarned,
    String? motivationMessage,
  }) async {
    try {
      final session = await _remote.completeSession(
        sessionId: sessionId,
        userId: userId,
        overallScore: overallScore,
        weakItemsReviewed: weakItemsReviewed,
        newWeakItems: newWeakItems,
        xpEarned: xpEarned,
        motivationMessage: motivationMessage,
      );
      return Right(session);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, MicroSession>> skipSession(String sessionId) async {
    try {
      throw const ServerException(
        message: 'skipSession userId kerak — provider orqali chaqiring',
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<MicroSession>>> getSessionHistory({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final sessions =
          await _remote.getSessionHistory(userId: userId, limit: limit);
      return Right(sessions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> getMotivationMessage({
    required String userId,
    required int currentStreak,
    required double averageScore,
    required String language,
  }) async {
    try {
      final message = await _remote.getMotivationMessage(
        userId: userId,
        currentStreak: currentStreak,
        averageScore: averageScore,
        language: language,
      );
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
