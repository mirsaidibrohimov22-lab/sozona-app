// lib/features/profile/domain/usecases/update_profile.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';
import 'package:my_first_app/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileParams extends Equatable {
  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final String? level;
  final String? preferredLanguage;
  final String? uiLanguage;
  final int? dailyGoalMinutes;

  const UpdateProfileParams({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.level,
    this.preferredLanguage,
    this.uiLanguage,
    this.dailyGoalMinutes,
  });

  @override
  List<Object?> get props => [userId, fullName, level];
}

class UpdateProfile implements UseCase<UserProfile, UpdateProfileParams> {
  final ProfileRepository _repo;
  UpdateProfile(this._repo);

  @override
  Future<Either<Failure, UserProfile>> call(UpdateProfileParams params) {
    return _repo.updateProfile(
      userId: params.userId,
      fullName: params.fullName,
      avatarUrl: params.avatarUrl,
      level: params.level,
      preferredLanguage: params.preferredLanguage,
      uiLanguage: params.uiLanguage,
      dailyGoalMinutes: params.dailyGoalMinutes,
    );
  }
}
