// lib/features/flashcard/domain/usecases/review_card.dart
// So'zona — Kartochka takrorlash use case
// SM-2 algoritmi asosida keyingi takrorlash sanasini belgilaydi

import 'package:dartz/dartz.dart';

import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/flashcards/domain/entities/flashcard_entity.dart';
import 'package:my_first_app/features/student/flashcards/domain/repositories/flashcard_repository.dart';

/// Kartochka takrorlash natijasini saqlash
class ReviewCard implements UseCase<FlashcardEntity, ReviewCardParams> {
  final FlashcardRepository repository;

  ReviewCard(this.repository);

  @override
  Future<Either<Failure, FlashcardEntity>> call(
    ReviewCardParams params,
  ) async {
    // Validatsiya
    if (params.cardId.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Kartochka topilmadi'),
      );
    }

    if (params.quality < 0 || params.quality > 5) {
      return const Left(
        ValidationFailure(
          message: 'Baholash 0 dan 5 gacha bo\'lishi kerak',
        ),
      );
    }

    return repository.reviewCard(
      cardId: params.cardId,
      quality: params.quality,
    );
  }
}

/// ReviewCard parametrlari
/// [quality] — SM-2 baholash:
///   0: To'liq unutilgan — Hech eslay olmadi
///   1: Noto'g'ri — Lekin ko'rganda esladi
///   2: Noto'g'ri — Lekin oson eslash mumkin edi
///   3: To'g'ri — Lekin qiyin edi
///   4: To'g'ri — Biroz o'ylanish kerak bo'ldi
///   5: To'g'ri — Mukammal, darhol esladi
class ReviewCardParams {
  final String cardId;
  final int quality;

  const ReviewCardParams({
    required this.cardId,
    required this.quality,
  });
}
