// lib/features/student/flashcards/domain/usecases/get_flashcards.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';

class GetFlashcards implements UseCase<List<FolderEntity>, String> {
  final FlashcardRepository _repo;
  GetFlashcards(this._repo);

  @override
  Future<Either<Failure, List<FolderEntity>>> call(String userId) =>
      _repo.getFolders(userId: userId);
}
