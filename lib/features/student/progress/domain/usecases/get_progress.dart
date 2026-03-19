// lib/features/student/progress/domain/usecases/get_progress.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/progress/domain/entities/progress.dart';
import 'package:my_first_app/features/student/progress/domain/repositories/progress_repository.dart';

class GetProgress implements UseCase<UserProgress, String> {
  final ProgressRepository _repo;
  GetProgress(this._repo);
  @override
  Future<Either<Failure, UserProgress>> call(String userId) =>
      _repo.getProgressStats(userId);
}
