// lib/features/flashcard/domain/usecases/create_card.dart
// So'zona — Yangi kartochka yaratish use case

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';

/// Yangi flashcard yaratish
class CreateCard implements UseCase<FlashcardEntity, CreateCardParams> {
  final FlashcardRepository repository;

  CreateCard(this.repository);

  @override
  Future<Either<Failure, FlashcardEntity>> call(
    CreateCardParams params,
  ) async {
    // Validatsiya
    final front = params.front.trim();
    final back = params.back.trim();

    if (front.isEmpty) {
      return const Left(
        ValidationFailure(message: 'So\'z kiritilishi shart'),
      );
    }

    if (back.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Tarjima kiritilishi shart'),
      );
    }

    if (front.length > 200) {
      return const Left(
        ValidationFailure(message: 'So\'z 200 belgidan oshmasligi kerak'),
      );
    }

    if (back.length > 200) {
      return const Left(
        ValidationFailure(message: 'Tarjima 200 belgidan oshmasligi kerak'),
      );
    }

    if (params.folderId.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Papka tanlanishi shart'),
      );
    }

    if (params.userId.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Foydalanuvchi topilmadi'),
      );
    }

    return repository.createCard(
      folderId: params.folderId,
      userId: params.userId,
      front: front,
      back: back,
      example: params.example?.trim(),
      pronunciation: params.pronunciation?.trim(),
      cefrLevel: params.cefrLevel,
      wordType: params.wordType,
      artikel: params.artikel,
    );
  }
}

/// CreateCard parametrlari
class CreateCardParams {
  final String folderId;
  final String userId;
  final String front;
  final String back;
  final String? example;
  final String? pronunciation;
  final String? cefrLevel;
  final String? wordType;
  final String? artikel;

  const CreateCardParams({
    required this.folderId,
    required this.userId,
    required this.front,
    required this.back,
    this.example,
    this.pronunciation,
    this.cefrLevel,
    this.wordType,
    this.artikel,
  });
}
