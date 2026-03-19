// lib/features/teacher/analytics/data/repositories/teacher_analytics_repository_impl.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/analytics/data/datasources/teacher_analytics_remote_datasource.dart';
import 'package:my_first_app/features/teacher/analytics/domain/entities/teacher_analytics.dart';
import 'package:my_first_app/features/teacher/analytics/domain/repositories/teacher_analytics_repository.dart';

class TeacherAnalyticsRepositoryImpl implements TeacherAnalyticsRepository {
  final TeacherAnalyticsRemoteDataSource _remote;
  final FirebaseFunctions _fn;
  TeacherAnalyticsRepositoryImpl(this._remote, this._fn);

  @override
  Future<Either<Failure, ClassAnalytics>> getClassAnalytics(
    String classId,
  ) async {
    try {
      return Right(await _remote.getClassAnalytics(classId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> getAiTeachingAdvice(String classId) async {
    try {
      final analytics = await _remote.getClassAnalytics(classId);
      final result = await _fn.httpsCallable('getTeachingAdvice').call({
        'classId': classId,
        'avgScore': analytics.avgScore,
        'skillBreakdown': analytics.skillBreakdown,
        'activeStudents': analytics.activeStudents,
        'totalStudents': analytics.totalStudents,
      });
      final data = result.data as Map<String, dynamic>;
      return Right(
        data['advice'] as String? ?? 'Sinfingiz yaxshi rivojlanmoqda!',
      );
    } catch (e) {
      return Left(AiFailure(message: 'AI maslahati yuklanmadi: $e'));
    }
  }
}
