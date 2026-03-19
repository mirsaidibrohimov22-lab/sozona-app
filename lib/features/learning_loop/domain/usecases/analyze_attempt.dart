// QO'YISH: lib/features/learning_loop/domain/usecases/analyze_attempt.dart
// So'zona — Urinishni tahlil qilish va zaif elementlarni yangilash

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/learning_loop/domain/repositories/learning_loop_repository.dart';

/// Urinish natijasini tahlil qilish parametrlari
class AnalyzeAttemptParams extends Equatable {
  final String userId;

  /// Kontent turi: "quiz", "flashcard", "listening", "speaking", "artikel"
  final String contentType;

  final String contentId;

  /// Har bir savol natijasi
  final List<AttemptAnswer> answers;

  const AnalyzeAttemptParams({
    required this.userId,
    required this.contentType,
    required this.contentId,
    required this.answers,
  });

  @override
  List<Object?> get props => [userId, contentType, contentId, answers];
}

/// Bitta savol javobi
class AttemptAnswer extends Equatable {
  final String questionId;
  final String term; // So'z yoki savol matni
  final String? translation; // Tarjimasi
  final String? context; // Misol gap
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;

  const AttemptAnswer({
    required this.questionId,
    required this.term,
    this.translation,
    this.context,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [questionId, isCorrect];
}

/// Urinishni tahlil qilish natijasi
class AnalyzeAttemptResult extends Equatable {
  /// Yangi yaratilgan zaif elementlar
  final List<WeakItem> newWeakItems;

  /// Yangilangan mavjud zaif elementlar
  final List<WeakItem> updatedWeakItems;

  /// O'zlashtirilgan elementlar soni
  final int masteredCount;

  const AnalyzeAttemptResult({
    required this.newWeakItems,
    required this.updatedWeakItems,
    this.masteredCount = 0,
  });

  @override
  List<Object?> get props => [newWeakItems, updatedWeakItems, masteredCount];
}

/// Urinishni tahlil qilish UseCase
/// Xato javoblarni Weak Items Pool ga qo'shadi
class AnalyzeAttempt
    implements UseCase<AnalyzeAttemptResult, AnalyzeAttemptParams> {
  final LearningLoopRepository _repository;

  AnalyzeAttempt(this._repository);

  @override
  Future<Either<Failure, AnalyzeAttemptResult>> call(
    AnalyzeAttemptParams params,
  ) async {
    // 1. Mavjud zaif elementlarni olish
    final existingResult = await _repository.getDueWeakItems(params.userId);

    return existingResult.fold(
      Left.new,
      (existingItems) async {
        final newWeakItems = <WeakItem>[];
        final updatedItems = <WeakItem>[];
        int masteredCount = 0;

        for (final answer in params.answers) {
          // Mavjud zaif elementda bormi?
          final existingItem = existingItems
              .where(
                (item) =>
                    item.sourceContentId == params.contentId &&
                    item.itemData.term == answer.term,
              )
              .firstOrNull;

          if (existingItem != null) {
            // Mavjud elementni yangilash
            final updated = answer.isCorrect
                ? existingItem.markCorrect()
                : existingItem.markIncorrect();

            final updateResult = await _repository.updateWeakItem(updated);
            updateResult.fold(
              (_) {},
              (item) {
                updatedItems.add(item);
                if (item.status == WeakItemStatus.mastered) {
                  masteredCount++;
                }
              },
            );
          } else if (!answer.isCorrect) {
            // Xato javob — yangi zaif element yaratish
            final sourceType = _parseSourceType(params.contentType);
            final addResult = await _repository.addWeakItem(
              userId: params.userId,
              sourceType: sourceType,
              sourceContentId: params.contentId,
              itemType: _parseItemType(params.contentType),
              itemData: WeakItemData(
                term: answer.term,
                translation: answer.translation,
                context: answer.context,
                correctAnswer: answer.correctAnswer,
              ),
            );

            addResult.fold(
              (_) {},
              newWeakItems.add,
            );
          }
        }

        return Right(
          AnalyzeAttemptResult(
            newWeakItems: newWeakItems,
            updatedWeakItems: updatedItems,
            masteredCount: masteredCount,
          ),
        );
      },
    );
  }

  WeakItemSource _parseSourceType(String contentType) {
    switch (contentType) {
      case 'flashcard':
        return WeakItemSource.flashcard;
      case 'quiz':
        return WeakItemSource.quiz;
      case 'listening':
        return WeakItemSource.listening;
      case 'speaking':
        return WeakItemSource.speaking;
      case 'artikel':
        return WeakItemSource.artikel;
      default:
        return WeakItemSource.quiz;
    }
  }

  String _parseItemType(String contentType) {
    switch (contentType) {
      case 'flashcard':
        return 'word';
      case 'artikel':
        return 'artikel_word';
      default:
        return 'question';
    }
  }
}
