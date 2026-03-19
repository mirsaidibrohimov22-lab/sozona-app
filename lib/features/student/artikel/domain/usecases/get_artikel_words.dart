// lib/features/student/artikel/domain/usecases/get_artikel_words.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';
import 'package:my_first_app/features/student/artikel/domain/repositories/artikel_repository.dart';

class GetArtikelWordsParams extends Equatable {
  final String userId;
  final String? topic;
  final String? level;
  const GetArtikelWordsParams({required this.userId, this.topic, this.level});
  @override
  List<Object?> get props => [userId, topic, level];
}

class GetArtikelWords
    implements UseCase<List<ArtikelWord>, GetArtikelWordsParams> {
  final ArtikelRepository _repo;
  GetArtikelWords(this._repo);
  @override
  Future<Either<Failure, List<ArtikelWord>>> call(GetArtikelWordsParams p) =>
      _repo.getArtikelWords(p.userId, topic: p.topic, level: p.level);
}
