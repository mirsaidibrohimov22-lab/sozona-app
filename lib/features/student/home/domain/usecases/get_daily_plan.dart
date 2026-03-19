// lib/features/student/home/domain/usecases/get_daily_plan.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/home/domain/entities/daily_plan.dart';
import 'package:my_first_app/features/student/home/domain/repositories/home_repository.dart';

class GetDailyPlan implements UseCase<DailyPlan, String> {
  final HomeRepository _repo;
  GetDailyPlan(this._repo);
  @override
  Future<Either<Failure, DailyPlan>> call(String userId) =>
      _repo.getDailyPlan(userId);
}
