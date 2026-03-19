// lib/features/profile/domain/usecases/request_account_delete.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/profile/domain/repositories/profile_repository.dart';

class RequestAccountDelete implements UseCase<void, String> {
  final ProfileRepository _repo;
  RequestAccountDelete(this._repo);

  @override
  Future<Either<Failure, void>> call(String userId) {
    return _repo.requestAccountDelete(userId);
  }
}
