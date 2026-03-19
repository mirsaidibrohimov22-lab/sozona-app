// lib/features/student/progress/domain/repositories/progress_repository.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/student/progress/domain/entities/progress.dart';

abstract class ProgressRepository {
  Future<Either<Failure, UserProgress>> getProgressStats(String userId);
  Future<Either<Failure, List<WeakItem>>> getWeakItems(String userId);
  Future<Either<Failure, void>> updateMasteryScore({
    required String userId,
    required String contentType,
    required String contentId,
    required double score,
  });
}
