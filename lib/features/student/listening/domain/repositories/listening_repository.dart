// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Listening Repository Interface
// QO'YISH: lib/features/student/listening/domain/repositories/listening_repository.dart
// ═══════════════════════════════════════════════════════════════

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';

/// Listening Repository — listening mashqlari bilan ishlash
abstract class ListeningRepository {
  /// Barcha listening mashqlarini olish
  ///
  /// [language] — til filter
  /// [level] — daraja filter
  /// [topic] — mavzu filter
  Future<Either<Failure, List<ListeningExercise>>> getListeningExercises({
    String? language,
    String? level,
    String? topic,
  });

  /// Bitta listening mashqni ID bo'yicha olish
  ///
  /// [exerciseId] — Mashq ID
  Future<Either<Failure, ListeningExercise>> getListeningDetail(
    String exerciseId,
  );

  /// Listening javoblarini yuborish va natijani olish
  ///
  /// [exerciseId] — Mashq ID
  /// [studentId] — O'quvchi ID
  /// [answers] — Javoblar {'q1': 'answer1', 'q2': 'answer2'}
  /// [timeSpent] — Sarflangan vaqt (sekundda)
  ///
  /// Returns: Score (foizda), correctAnswers, wrongAnswers
  Future<Either<Failure, Map<String, dynamic>>> submitListeningAnswers({
    required String exerciseId,
    required String studentId,
    required Map<String, String> answers,
    required int timeSpent,
  });

  /// Listening mashqni offline uchun saqlash
  Future<Either<Failure, bool>> cacheExercise(ListeningExercise exercise);

  /// Offline saqlangan mashqlarni olish
  Future<Either<Failure, List<ListeningExercise>>> getCachedExercises();
}
