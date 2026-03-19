// lib/features/student/home/domain/repositories/home_repository.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/home/domain/entities/daily_plan.dart';
import 'package:my_first_app/features/student/home/domain/entities/streak.dart';

abstract class HomeRepository {
  Future<Either<Failure, DailyPlan>> getDailyPlan(String userId);
  Future<Either<Failure, Streak>> getStreak(String userId);
  Future<Either<Failure, void>> completeTask(String userId, String taskId);
  Future<Either<Failure, String>> joinClass(String userId, String joinCode);
}
