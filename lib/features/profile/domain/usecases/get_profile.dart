// QO'YISH: lib/features/profile/domain/usecases/get_profile.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/profile/domain/entities/profile.dart';
import 'package:my_first_app/features/profile/domain/repositories/profile_repository.dart';

class GetProfile implements UseCase<UserProfile, String> {
  final ProfileRepository _repo;
  GetProfile(this._repo);

  @override
  Future<Either<Failure, UserProfile>> call(String userId) {
    return _repo.getProfile(userId);
  }
}
