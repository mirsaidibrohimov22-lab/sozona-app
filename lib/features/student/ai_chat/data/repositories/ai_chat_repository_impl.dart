// lib/features/student/ai_chat/data/repositories/ai_chat_repository_impl.dart
// So'zona — AI Chat repository implementatsiyasi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/ai_chat/data/datasources/chat_remote_datasource.dart';
import 'package:my_first_app/features/student/ai_chat/domain/entities/chat_message.dart';
import 'package:my_first_app/features/student/ai_chat/domain/repositories/chat_repository.dart';

class AiChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  AiChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String userId,
    required String message,
    required String language,
    required String level,
    required List<ChatMessage> history,
  }) async {
    try {
      final result = await remoteDataSource.sendMessage(
        userId: userId,
        text: message,
        language: language,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Kutilmagan xatolik: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatHistory(String userId) async {
    try {
      final history = await remoteDataSource.getHistory(userId);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Tarix yuklanmadi: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory(String userId) async {
    try {
      await remoteDataSource.clearHistory(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: "O'chirishda xatolik: $e"));
    }
  }
}
