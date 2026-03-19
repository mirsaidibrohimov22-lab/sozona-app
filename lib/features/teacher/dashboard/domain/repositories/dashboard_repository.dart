// lib/features/teacher/dashboard/domain/repositories/dashboard_repository.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats(String teacherId);
}
