// lib/features/student/artikel/domain/repositories/artikel_repository.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';

abstract class ArtikelRepository {
  Future<Either<Failure, List<ArtikelWord>>> getArtikelWords(
    String userId, {
    String? topic,
    String? level,
  });
  Future<Either<Failure, bool>> submitAnswer({
    required String userId,
    required String wordId,
    required String selectedArtikel,
  });
}
