// lib/features/student/home/domain/usecases/get_streak.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/home/domain/entities/streak.dart';
import 'package:my_first_app/features/student/home/domain/repositories/home_repository.dart';

class GetStreak implements UseCase<Streak, String> {
  final HomeRepository _repo;
  GetStreak(this._repo);
  @override
  Future<Either<Failure, Streak>> call(String userId) =>
      _repo.getStreak(userId);
}
