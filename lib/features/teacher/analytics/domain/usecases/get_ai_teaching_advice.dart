// lib/features/teacher/analytics/domain/usecases/get_ai_teaching_advice.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/teacher/analytics/domain/repositories/teacher_analytics_repository.dart';

class GetAiTeachingAdvice implements UseCase<String, String> {
  final TeacherAnalyticsRepository _repo;
  GetAiTeachingAdvice(this._repo);

  @override
  Future<Either<Failure, String>> call(String classId) =>
      _repo.getAiTeachingAdvice(classId);
}
