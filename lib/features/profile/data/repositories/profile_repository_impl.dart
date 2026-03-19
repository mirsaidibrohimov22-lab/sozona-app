// ═══════════════════════════════════════════════════════════════
// TO'LIQ FAYL — COPY-PASTE QILING
// PATH: lib/features/profile/data/repositories/profile_repository_impl.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';
import 'package:my_first_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remote})
      : _remote = remote;

  // ─── getProfile ───────────────────────────────────────────
  @override
  Future<Either<Failure, UserProfile>> getProfile(String userId) async {
    try {
      final profile = await _remote.getProfile(userId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── updateProfile ────────────────────────────────────────
  @override
  Future<Either<Failure, UserProfile>> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? level,
    String? preferredLanguage,
    String? uiLanguage,
    int? dailyGoalMinutes,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (fullName != null) fields['fullName'] = fullName;
      if (avatarUrl != null) fields['avatarUrl'] = avatarUrl;
      if (level != null) fields['level'] = level;
      if (preferredLanguage != null) {
        fields['preferredLanguage'] = preferredLanguage;
      }
      if (uiLanguage != null) fields['uiLanguage'] = uiLanguage;
      if (dailyGoalMinutes != null) {
        fields['dailyGoalMinutes'] = dailyGoalMinutes;
      }
      final profile = await _remote.updateProfile(userId, fields);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── updatePreferences ────────────────────────────────────
  @override
  Future<Either<Failure, UserProfile>> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async {
    try {
      // Preferences uchun nested map ishlaydi — Timestamp bug yo'q
      final fields = {
        'preferences': {
          'microSessionEnabled': preferences.microSessionEnabled,
          'microSessionIntervalMin': preferences.microSessionIntervalMin,
          'microSessionDurationMin': preferences.microSessionDurationMin,
          'premiumTtsEnabled': preferences.premiumTtsEnabled,
          'studentQuizAddEnabled': preferences.studentQuizAddEnabled,
        },
      };
      final profile = await _remote.updateProfile(userId, fields);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── updateNotificationSettings ───────────────────────────
  // ✅ BUG FIX: Eski kod updateProfile() chaqirar edi — bu Timestamp
  // bilan notifications fieldini aralashtirar edi → runtime crash.
  // Yangi kod: to'g'ridan datasource.updateNotificationSettings() ga o'tadi.
  @override
  Future<Either<Failure, UserProfile>> updateNotificationSettings({
    required String userId,
    required UserNotificationSettings notifications,
  }) async {
    try {
      final profile = await _remote.updateNotificationSettings(
        userId,
        notifications,
      );
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── uploadAvatar ─────────────────────────────────────────
  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      final url = await _remote.uploadAvatar(userId, filePath);
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── requestDataExport ────────────────────────────────────
  @override
  Future<Either<Failure, void>> requestDataExport(String userId) async {
    try {
      await _remote.requestDataExport(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // ─── requestAccountDelete ─────────────────────────────────
  @override
  Future<Either<Failure, void>> requestAccountDelete(String userId) async {
    try {
      await _remote.requestAccountDelete(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
