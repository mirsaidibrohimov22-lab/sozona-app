// lib/features/student/flashcards/domain/usecases/sync_offline_flashcards.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';

class SyncOfflineFlashcards implements UseCase<void, String> {
  SyncOfflineFlashcards();

  @override
  Future<Either<Failure, void>> call(String userId) async {
    // Sync handled at repository level via offline-first strategy
    return const Right(null);
  }
}
