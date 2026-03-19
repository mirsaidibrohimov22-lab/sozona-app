// lib/features/student/flashcards/domain/usecases/update_mastery.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';

class UpdateMasteryParams extends Equatable {
  final String cardId;
  final int quality;
  const UpdateMasteryParams({required this.cardId, required this.quality});
  @override
  List<Object?> get props => [cardId, quality];
}

class UpdateMastery implements UseCase<FlashcardEntity, UpdateMasteryParams> {
  final FlashcardRepository _repo;
  UpdateMastery(this._repo);

  @override
  Future<Either<Failure, FlashcardEntity>> call(UpdateMasteryParams p) =>
      _repo.reviewCard(cardId: p.cardId, quality: p.quality);
}
