// lib/features/flashcard/domain/usecases/get_folders.dart
// So'zona — Papkalarni olish use case

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';

/// Foydalanuvchi papkalarini olish
class GetFolders implements UseCase<List<FolderEntity>, GetFoldersParams> {
  final FlashcardRepository repository;

  GetFolders(this.repository);

  @override
  Future<Either<Failure, List<FolderEntity>>> call(
    GetFoldersParams params,
  ) async {
    // Validatsiya
    if (params.userId.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Foydalanuvchi topilmadi'),
      );
    }

    return repository.getFolders(userId: params.userId);
  }
}

/// GetFolders parametrlari
class GetFoldersParams {
  final String userId;

  const GetFoldersParams({required this.userId});
}
