import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/publishing/data/datasources/publishing_remote_datasource.dart';
import 'package:my_first_app/features/teacher/publishing/domain/repositories/publishing_repository.dart';

class PublishingRepositoryImpl implements PublishingRepository {
  final PublishingRemoteDataSource _remote;

  PublishingRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, void>> publishContent({
    required GeneratedContent content,
    required String classId,
    required String title,
    String? description,
    bool sendNotification = true,
  }) async {
    try {
      await _remote.publishContent(
        contentId: content.id,
        contentType: content.type.name,
        classIds: [classId],
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleContent({
    required GeneratedContent content,
    required String classId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    bool sendNotification = true,
  }) async {
    try {
      await _remote.scheduleContent(
        contentId: content.id,
        contentType: content.type.name,
        classIds: [classId],
        scheduledAt: scheduledAt,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
