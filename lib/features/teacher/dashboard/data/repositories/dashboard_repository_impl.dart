// lib/features/teacher/dashboard/data/repositories/dashboard_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:my_first_app/features/teacher/dashboard/domain/entities/dashboard_stats.dart';
import 'package:my_first_app/features/teacher/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remote;
  DashboardRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats(
    String teacherId,
  ) async {
    try {
      return Right(await _remote.getDashboardStats(teacherId));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
