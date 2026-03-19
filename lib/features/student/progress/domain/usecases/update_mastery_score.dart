// lib/features/student/progress/domain/usecases/update_mastery_score.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/progress/domain/repositories/progress_repository.dart';

class UpdateMasteryScoreParams extends Equatable {
  final String userId;
  final String contentType;
  final String contentId;
  final double score;
  const UpdateMasteryScoreParams({
    required this.userId,
    required this.contentType,
    required this.contentId,
    required this.score,
  });
  @override
  List<Object?> get props => [userId, contentType, contentId];
}

class UpdateMasteryScore implements UseCase<void, UpdateMasteryScoreParams> {
  final ProgressRepository _repo;
  UpdateMasteryScore(this._repo);
  @override
  Future<Either<Failure, void>> call(UpdateMasteryScoreParams p) =>
      _repo.updateMasteryScore(
        userId: p.userId,
        contentType: p.contentType,
        contentId: p.contentId,
        score: p.score,
      );
}
