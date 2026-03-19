// lib/features/teacher/dashboard/domain/usecases/get_dashboard_stats.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/dashboard/domain/entities/dashboard_stats.dart';
import 'package:my_first_app/features/teacher/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardStats implements UseCase<DashboardStats, String> {
  final DashboardRepository _repo;
  GetDashboardStats(this._repo);
  @override
  Future<Either<Failure, DashboardStats>> call(String teacherId) =>
      _repo.getDashboardStats(teacherId);
}
