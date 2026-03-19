// lib/features/student/ai_chat/domain/usecases/get_proactive_suggestion.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/usecases/usecase.dart';

class ProactiveSuggestion {
  final String message;
  final String type;
  final String urgency;
  const ProactiveSuggestion({
    required this.message,
    required this.type,
    required this.urgency,
  });
}

class GetProactiveSuggestion implements UseCase<ProactiveSuggestion, String> {
  final FirebaseFunctions _fn;
  final FirebaseFirestore _db;
  GetProactiveSuggestion(this._fn, this._db);

  @override
  Future<Either<Failure, ProactiveSuggestion>> call(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final progressDoc = await _db.collection('progress').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final progressData = progressDoc.data() ?? {};
      final lastActive =
          (progressData['lastActiveDate'] as Timestamp?)?.toDate();
      final daysSince =
          lastActive == null ? 0 : DateTime.now().difference(lastActive).inDays;

      final result = await _fn.httpsCallable('getProactiveSuggestion').call({
        'userId': userId,
        'language': userData['learningLanguage'] ?? 'de',
        'level': userData['currentLevel'] ?? 'A1',
        'weakAreas': List<String>.from(progressData['weakAreas'] ?? []),
        'daysSinceLastSession': daysSince,
        'currentStreak': progressData['currentStreak'] ?? 0,
      });
      final data = result.data as Map<String, dynamic>;
      return Right(
        ProactiveSuggestion(
          message: data['message'] as String? ?? 'Bugun mashq qiling!',
          type: data['suggestionType'] as String? ?? 'quiz',
          urgency: data['urgency'] as String? ?? 'medium',
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      return Left(AiFailure(message: e.message ?? 'AI xatosi'));
    } catch (e) {
      return Left(ServerFailure(message: 'Tavsiya yuklanmadi: $e'));
    }
  }
}
