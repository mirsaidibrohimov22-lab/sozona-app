// QO'YISH: lib/features/profile/domain/repositories/profile_repository.dart

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile(String userId);
  Future<Either<Failure, UserProfile>> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
    String? avatarVisibility,
    String? level,
    String? preferredLanguage,
    String? uiLanguage,
    int? dailyGoalMinutes,
  });
  Future<Either<Failure, UserProfile>> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  });
  Future<Either<Failure, UserProfile>> updateNotificationSettings({
    required String userId,
    required UserNotificationSettings notifications,
  });
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required String filePath,
  });
  // ✅ YANGI: Rasmni o'chirish
  Future<Either<Failure, void>> deleteAvatar({required String userId});
  Future<Either<Failure, void>> requestDataExport(String userId);
  Future<Either<Failure, void>> requestAccountDelete(String userId);
}
