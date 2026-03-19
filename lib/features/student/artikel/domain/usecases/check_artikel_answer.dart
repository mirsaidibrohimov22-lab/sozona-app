// lib/features/student/artikel/domain/usecases/check_artikel_answer.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/artikel/domain/repositories/artikel_repository.dart';

class CheckArtikelAnswerParams extends Equatable {
  final String userId;
  final String wordId;
  final String selectedArtikel;
  const CheckArtikelAnswerParams({
    required this.userId,
    required this.wordId,
    required this.selectedArtikel,
  });
  @override
  List<Object?> get props => [userId, wordId, selectedArtikel];
}

class CheckArtikelAnswer implements UseCase<bool, CheckArtikelAnswerParams> {
  final ArtikelRepository _repo;
  CheckArtikelAnswer(this._repo);
  @override
  Future<Either<Failure, bool>> call(CheckArtikelAnswerParams p) =>
      _repo.submitAnswer(
        userId: p.userId,
        wordId: p.wordId,
        selectedArtikel: p.selectedArtikel,
      );
}
