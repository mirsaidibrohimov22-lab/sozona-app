// lib/features/student/progress/domain/usecases/get_weak_items.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/learning_loop/domain/entities/weak_item_pool.dart';
import 'package:my_first_app/features/student/progress/domain/repositories/progress_repository.dart';

class GetWeakItems implements UseCase<List<WeakItem>, String> {
  final ProgressRepository _repo;
  GetWeakItems(this._repo);
  @override
  Future<Either<Failure, List<WeakItem>>> call(String userId) =>
      _repo.getWeakItems(userId);
}
