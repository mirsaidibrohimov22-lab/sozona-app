// lib/features/teacher/analytics/domain/usecases/get_class_analytics.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/analytics/domain/entities/teacher_analytics.dart';
import 'package:my_first_app/features/teacher/analytics/domain/repositories/teacher_analytics_repository.dart';

class GetClassAnalytics implements UseCase<ClassAnalytics, String> {
  final TeacherAnalyticsRepository _repo;
  GetClassAnalytics(this._repo);
  @override
  Future<Either<Failure, ClassAnalytics>> call(String classId) =>
      _repo.getClassAnalytics(classId);
}
