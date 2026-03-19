// QO'YISH: lib/features/profile/domain/usecases/update_preferences.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';
import 'package:my_first_app/features/profile/domain/repositories/profile_repository.dart';

class UpdatePreferencesParams extends Equatable {
  final String userId;
  final UserPreferences preferences;
  const UpdatePreferencesParams({
    required this.userId,
    required this.preferences,
  });
  @override
  List<Object?> get props => [userId];
}

class UpdatePreferences
    implements UseCase<UserProfile, UpdatePreferencesParams> {
  final ProfileRepository _repo;
  UpdatePreferences(this._repo);

  @override
  Future<Either<Failure, UserProfile>> call(UpdatePreferencesParams params) {
    return _repo.updatePreferences(
      userId: params.userId,
      preferences: params.preferences,
    );
  }
}
