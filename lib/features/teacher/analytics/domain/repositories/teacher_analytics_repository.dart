// lib/features/teacher/analytics/domain/repositories/teacher_analytics_repository.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/analytics/domain/entities/teacher_analytics.dart';

abstract class TeacherAnalyticsRepository {
  Future<Either<Failure, ClassAnalytics>> getClassAnalytics(String classId);
  Future<Either<Failure, String>> getAiTeachingAdvice(String classId);
}
