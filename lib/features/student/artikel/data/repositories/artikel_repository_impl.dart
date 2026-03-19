// lib/features/student/artikel/data/repositories/artikel_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/artikel/data/datasources/artikel_local_datasource.dart';
import 'package:my_first_app/features/student/artikel/data/datasources/artikel_remote_datasource.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';
import 'package:my_first_app/features/student/artikel/domain/repositories/artikel_repository.dart';

class ArtikelRepositoryImpl implements ArtikelRepository {
  final ArtikelRemoteDataSource _remote;
  final ArtikelLocalDataSource _local;
  ArtikelRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, List<ArtikelWord>>> getArtikelWords(
    String userId, {
    String? topic,
    String? level,
  }) async {
    try {
      final words =
          await _remote.getArtikelWords(userId, topic: topic, level: level);
      await _local.cacheWords(words);
      return Right(words);
    } on ServerException catch (_) {
      final cached = await _local.getCachedWords();
      if (cached.isNotEmpty) return Right(cached);
      return const Left(ServerFailure(message: 'Artikel so\'zlar yuklanmadi'));
    }
  }

  @override
  Future<Either<Failure, bool>> submitAnswer({
    required String userId,
    required String wordId,
    required String selectedArtikel,
  }) async {
    try {
      return Right(
        await _remote.submitAnswer(
          userId: userId,
          wordId: wordId,
          selectedArtikel: selectedArtikel,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
