// lib/features/student/speaking/domain/repositories/speaking_repository.dart
// So'zona — Speaking Repository (Abstract)
// Bu fayl O'ZGARTIRILMAYDI — faqat interface ta'rifi

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';

abstract class SpeakingRepository {
  /// Yangi speaking dialog yaratish (Cloud Function)
  Future<Either<Failure, SpeakingExercise>> generateDialog({
    required String topic,
    required String language,
    required String level,
  });

  /// Firestore dan speaking mashqlarini olish
  Future<Either<Failure, List<SpeakingExercise>>> getExercises({
    String? language,
    String? level,
  });

  /// Student xabarini yuborish va AI javob olish
  Future<Either<Failure, Map<String, dynamic>>> sendMessage({
    required String exerciseId,
    required String userMessage,
    required int turnIndex,
  });

  /// Dialog tugagandan keyin umumiy feedback olish
  Future<Either<Failure, Map<String, dynamic>>> getFeedback({
    required String exerciseId,
    required List<String> userMessages,
  });
}
