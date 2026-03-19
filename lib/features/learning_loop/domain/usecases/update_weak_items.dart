// QO'YISH: lib/features/learning_loop/domain/usecases/update_weak_items.dart
// So'zona — Zaif elementlarni yangilash (to'g'ri/xato javob asosida)

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/learning_loop/domain/repositories/learning_loop_repository.dart';

class UpdateWeakItemsParams extends Equatable {
  /// Yangilanishi kerak bo'lgan elementlar va ularning javoblari
  final List<WeakItemAnswer> answers;

  const UpdateWeakItemsParams({required this.answers});

  @override
  List<Object?> get props => [answers];
}

class WeakItemAnswer extends Equatable {
  final WeakItem item;
  final bool isCorrect;

  const WeakItemAnswer({required this.item, required this.isCorrect});

  @override
  List<Object?> get props => [item.id, isCorrect];
}

/// Zaif elementlarni batch yangilash
class UpdateWeakItems
    implements UseCase<List<WeakItem>, UpdateWeakItemsParams> {
  final LearningLoopRepository _repository;

  UpdateWeakItems(this._repository);

  @override
  Future<Either<Failure, List<WeakItem>>> call(
    UpdateWeakItemsParams params,
  ) async {
    // Har bir javobga qarab elementni yangilash
    final updatedItems = params.answers.map((answer) {
      return answer.isCorrect
          ? answer.item.markCorrect()
          : answer.item.markIncorrect();
    }).toList();

    // Batch yangilash
    return _repository.batchUpdateWeakItems(updatedItems);
  }
}
