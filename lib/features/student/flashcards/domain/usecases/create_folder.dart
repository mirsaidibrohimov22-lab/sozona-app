// lib/features/flashcard/domain/usecases/create_folder.dart
// So'zona — Yangi papka yaratish use case

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/folder_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';

/// Yangi papka yaratish
class CreateFolder implements UseCase<FolderEntity, CreateFolderParams> {
  final FlashcardRepository repository;

  CreateFolder(this.repository);

  @override
  Future<Either<Failure, FolderEntity>> call(
    CreateFolderParams params,
  ) async {
    // Validatsiya
    final name = params.name.trim();

    if (name.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Papka nomi kiritilishi shart'),
      );
    }

    if (name.length < 2) {
      return const Left(
        ValidationFailure(
          message: 'Papka nomi kamida 2 belgidan iborat bo\'lishi kerak',
        ),
      );
    }

    if (name.length > 50) {
      return const Left(
        ValidationFailure(message: 'Papka nomi 50 belgidan oshmasligi kerak'),
      );
    }

    if (params.userId.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Foydalanuvchi topilmadi'),
      );
    }

    return repository.createFolder(
      userId: params.userId,
      name: name,
      description: params.description?.trim(),
      color: params.color,
      emoji: params.emoji,
      language: params.language,
      cefrLevel: params.cefrLevel,
    );
  }
}

/// CreateFolder parametrlari
class CreateFolderParams {
  final String userId;
  final String name;
  final String? description;
  final FolderColor color;
  final String? emoji;
  final String language;
  final String? cefrLevel;

  const CreateFolderParams({
    required this.userId,
    required this.name,
    this.description,
    this.color = FolderColor.blue,
    this.emoji,
    this.language = 'english',
    this.cefrLevel,
  });
}
