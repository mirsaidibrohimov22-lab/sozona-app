// lib/features/teacher/content_generator/data/repositories/content_gen_repository_impl.dart
// Content Generator Repository Implementation — Domain interfaceni amalga oshirish

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/network/network_info.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/repositories/content_generator_repository.dart';
import 'package:my_first_app/features/teacher/content_generator/data/datasources/content_gen_remote_datasource.dart';

/// Content Generator Repository Implementation
class ContentGeneratorRepositoryImpl implements ContentGeneratorRepository {
  final ContentGeneratorRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ContentGeneratorRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, GeneratedContent>> generateQuiz({
    required String language,
    required String level,
    required String topic,
    required int questionCount,
    String difficulty = 'medium',
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
          NetworkFailure(message: 'Internet bilan bog\'lanish yo\'q'));
    }
    try {
      final result = await remoteDataSource.generateQuiz(
        language: language,
        level: level,
        topic: topic,
        questionCount: questionCount,
        difficulty: difficulty,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Kutilmagan xatolik: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GeneratedContent>> generateFlashcards({
    required String language,
    required String level,
    required String topic,
    required int cardCount,
    bool includeExamples = true,
    bool includePronunciation = true,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
          NetworkFailure(message: 'Internet bilan bog\'lanish yo\'q'));
    }
    try {
      final result = await remoteDataSource.generateFlashcards(
        language: language,
        level: level,
        topic: topic,
        cardCount: cardCount,
        includeExamples: includeExamples,
        includePronunciation: includePronunciation,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Kutilmagan xatolik: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GeneratedContent>> generateListening({
    required String language,
    required String level,
    required String topic,
    int duration = 120,
    int questionCount = 5,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
          NetworkFailure(message: 'Internet bilan bog\'lanish yo\'q'));
    }
    try {
      final result = await remoteDataSource.generateListening(
        language: language,
        level: level,
        topic: topic,
        duration: duration,
        questionCount: questionCount,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(
          ServerFailure(message: 'Kutilmagan xatolik: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GeneratedContent>> getGeneratedContent({
    required String contentId,
  }) async {
    return const Left(
        CacheFailure(message: 'Bu funksiya hali ishlab chiqilmagan'));
  }

  @override
  Future<Either<Failure, GeneratedContent>> updateGeneratedContent({
    required String contentId,
    required Map<String, dynamic> updatedData,
  }) async {
    return const Left(
        CacheFailure(message: 'Bu funksiya hali ishlab chiqilmagan'));
  }

  @override
  Future<Either<Failure, void>> deleteGeneratedContent({
    required String contentId,
  }) async {
    return const Left(
        CacheFailure(message: 'Bu funksiya hali ishlab chiqilmagan'));
  }
}
