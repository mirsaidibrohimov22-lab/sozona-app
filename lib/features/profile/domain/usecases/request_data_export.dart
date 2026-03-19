// lib/features/profile/domain/usecases/request_data_export.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/profile/domain/repositories/profile_repository.dart';

class RequestDataExport implements UseCase<void, String> {
  final ProfileRepository _repo;
  RequestDataExport(this._repo);

  @override
  Future<Either<Failure, void>> call(String userId) =>
      _repo.requestDataExport(userId);
}
