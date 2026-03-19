// lib/features/student/speaking/data/repositories/speaking_repository_impl.dart
// So'zona — Speaking Repository Implementation
// ✅ v2.0: HAQIQIY AI assessment (hardcoded natija O'CHIRILDI)
// ✅ v2.0: Activity tracking qo'shildi
// ✅ v3.0 FIX: language: 'en', level: 'A1' hardcode O'CHIRILDI
// ✅ YANGI: assessVoice() — ovoz yozish + AI baholash (speaking_screen.dart uchun)

import 'package:dartz/dartz.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/error/failures.dart';
import 'package:my_first_app/core/services/member_progress_service.dart';
import 'package:my_first_app/features/student/speaking/data/datasources/speaking_remote_datasource.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';
import 'package:my_first_app/features/student/speaking/domain/repositories/speaking_repository.dart';

class SpeakingRepositoryImpl implements SpeakingRepository {
  final SpeakingRemoteDataSource remoteDataSource;

  // Aktiv sessiya exercise'ni saqlaymiz — getFeedback language/level ni olish uchun
  SpeakingExercise? _activeExercise;

  // ✅ FIX: member progress yangilash uchun userId saqlaymiz
  String _activeUserId = '';

  SpeakingRepositoryImpl({required this.remoteDataSource});

  /// Aktiv exercise'ni o'rnatish
  void setActiveExercise(SpeakingExercise exercise, {String userId = ''}) {
    _activeExercise = exercise;
    _activeUserId = userId;
  }

  @override
  Future<Either<Failure, SpeakingExercise>> generateDialog({
    required String topic,
    required String language,
    required String level,
  }) async {
    try {
      final exercise = await remoteDataSource.generateDialog(
        topic: topic,
        language: language,
        level: level,
      );
      _activeExercise = exercise;
      return Right(exercise);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Dialog yaratish xatosi: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SpeakingExercise>>> getExercises({
    String? language,
    String? level,
  }) async {
    try {
      final exercises = await remoteDataSource.getExercises(
        language: language,
        level: level,
      );
      return Right(exercises);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Mashqlar yuklanmadi: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendMessage({
    required String exerciseId,
    required String userMessage,
    required int turnIndex,
  }) async {
    try {
      final result = await remoteDataSource.sendMessage(
        exerciseId: exerciseId,
        userMessage: userMessage,
        turnIndex: turnIndex,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Xabar yuborish xatosi: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ YANGI: assessVoice — to'g'ridan-to'g'ri ovoz baholash
  // speaking_screen.dart mikrofon orqali olingan matni bu yerga yuboradi
  // ═══════════════════════════════════════════════════════════════
  Future<Either<Failure, Map<String, dynamic>>> assessVoice({
    required String exerciseId,
    required String transcribedText,
    required int audioDuration,
    required String language,
    required String level,
    required String topic,
  }) async {
    try {
      if (transcribedText.trim().isEmpty) {
        return const Right({
          'pronunciationScore': 0,
          'grammarScore': 0,
          'fluencyScore': 0,
          'vocabularyScore': 0,
          'overallScore': 0,
          'overallFeedback': "Hech narsa aytilmadi. Qaytadan urinib ko'ring.",
          'improvementTips': ['Kamida bir gap ayting'],
          'grammarErrors': <Map<String, dynamic>>[],
        });
      }

      // Cloud Function ga yuborish
      final assessment = await remoteDataSource.assessSpeakingResponse(
        taskId: exerciseId,
        language: language,
        level: level,
        topic: topic,
        transcribedText: transcribedText,
        audioDuration: audioDuration,
      );

      // Activity tracking
      final overallScore = (assessment['overallScore'] as num?)?.toInt() ?? 0;
      final grammarErrors = (assessment['grammarErrors'] as List?)
              ?.map((e) => (e as Map)['rule']?.toString() ?? '')
              .where((r) => r.isNotEmpty)
              .toList() ??
          <String>[];

      await remoteDataSource.recordSpeakingActivity(
        topic: topic,
        language: language,
        level: level,
        overallScore: overallScore,
        responseTime: audioDuration,
        grammarErrors: grammarErrors,
      );

      // ✅ FIX: Member progress yangilash (averageScore, totalAttempts)
      if (_activeUserId.isNotEmpty) {
        await MemberProgressService.instance.recordAttempt(
          userId: _activeUserId,
          scorePercent: overallScore.toDouble(),
          skillType: 'speaking',
        );
      }

      // speaking_screen.dart ga qaytariladigan format
      return Right({
        'pronunciationScore': assessment['pronunciationScore'] ?? 0,
        'grammarScore': assessment['grammarScore'] ?? 0,
        'fluencyScore': assessment['fluencyScore'] ?? 0,
        'vocabularyScore': assessment['vocabularyScore'] ?? 0,
        'overallScore': overallScore,
        'overallFeedback': assessment['overallFeedback'] ?? '',
        'pronunciationFeedback': assessment['pronunciationFeedback'] ?? '',
        'grammarFeedback': assessment['grammarFeedback'] ?? '',
        'fluencyFeedback': assessment['fluencyFeedback'] ?? '',
        'grammarErrors': assessment['grammarErrors'] ?? [],
        'vocabularyUsed': assessment['vocabularyUsed'] ?? [],
        'improvementTips': assessment['improvementTips'] ?? [],
        'nextTask': assessment['nextTask'],
        'metadata': assessment['metadata'],
      });
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Ovoz baholash xatosi: $e'));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // getFeedback — dialog rejimida feedback (eski metod saqlanadi)
  // ═══════════════════════════════════════════════════════════════
  @override
  Future<Either<Failure, Map<String, dynamic>>> getFeedback({
    required String exerciseId,
    required List<String> userMessages,
  }) async {
    try {
      final fullText = userMessages.join('. ').trim();

      if (fullText.isEmpty) {
        return const Right({
          'pronunciationScore': 0,
          'grammarScore': 0,
          'fluencyScore': 0,
          'vocabularyScore': 0,
          'overallScore': 0,
          'overallFeedback': "Hech narsa aytilmadi. Qaytadan urinib ko'ring.",
          'improvementTips': ['Kamida bir gap ayting'],
          'grammarErrors': <Map<String, dynamic>>[],
        });
      }

      final exerciseLanguage = _activeExercise?.language ?? 'en';
      final exerciseLevel = _activeExercise?.level ?? 'A1';
      final exerciseTopic = _activeExercise?.topic ?? 'general';

      final assessment = await remoteDataSource.assessSpeakingResponse(
        taskId: exerciseId,
        language: exerciseLanguage,
        level: exerciseLevel,
        topic: exerciseTopic,
        transcribedText: fullText,
        audioDuration: fullText.split(' ').length * 2,
      );

      final overallScore = (assessment['overallScore'] as num?)?.toInt() ?? 0;
      final grammarErrors = (assessment['grammarErrors'] as List?)
              ?.map((e) => (e as Map)['rule']?.toString() ?? '')
              .where((r) => r.isNotEmpty)
              .toList() ??
          <String>[];

      await remoteDataSource.recordSpeakingActivity(
        topic: exerciseTopic,
        language: exerciseLanguage,
        level: exerciseLevel,
        overallScore: overallScore,
        responseTime: fullText.split(' ').length * 2,
        grammarErrors: grammarErrors,
      );

      // ✅ FIX: Member progress yangilash (averageScore, totalAttempts)
      if (_activeUserId.isNotEmpty) {
        await MemberProgressService.instance.recordAttempt(
          userId: _activeUserId,
          scorePercent: overallScore.toDouble(),
          skillType: 'speaking',
        );
      }

      _activeExercise = null;
      _activeUserId = '';

      return Right({
        'score': overallScore,
        'pronunciationScore': assessment['pronunciationScore'] ?? 0,
        'grammarScore': assessment['grammarScore'] ?? 0,
        'fluencyScore': assessment['fluencyScore'] ?? 0,
        'vocabularyScore': assessment['vocabularyScore'] ?? 0,
        'overallScore': overallScore,
        'feedback': assessment['overallFeedback'] ?? '',
        'pronunciationFeedback': assessment['pronunciationFeedback'] ?? '',
        'grammarFeedback': assessment['grammarFeedback'] ?? '',
        'fluencyFeedback': assessment['fluencyFeedback'] ?? '',
        'strengths': _extractStrengths(assessment),
        'improvements': _extractImprovements(assessment),
        'grammarErrors': assessment['grammarErrors'] ?? [],
        'improvementTips': assessment['improvementTips'] ?? [],
      });
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Baholash xatosi: $e'));
    }
  }

  List<String> _extractStrengths(Map<String, dynamic> assessment) {
    final strengths = <String>[];
    if ((assessment['pronunciationScore'] as num? ?? 0) >= 70) {
      strengths.add('Talaffuz');
    }
    if ((assessment['grammarScore'] as num? ?? 0) >= 70) {
      strengths.add('Grammatika');
    }
    if ((assessment['fluencyScore'] as num? ?? 0) >= 70) {
      strengths.add('Ravonlik');
    }
    if ((assessment['vocabularyScore'] as num? ?? 0) >= 70) {
      strengths.add("So'z boyligi");
    }
    if (strengths.isEmpty) strengths.add('Urinish');
    return strengths;
  }

  List<String> _extractImprovements(Map<String, dynamic> assessment) {
    final improvements = <String>[];
    if ((assessment['pronunciationScore'] as num? ?? 0) < 60) {
      improvements.add('Talaffuz');
    }
    if ((assessment['grammarScore'] as num? ?? 0) < 60) {
      improvements.add('Grammatika');
    }
    if ((assessment['fluencyScore'] as num? ?? 0) < 60) {
      improvements.add('Ravonlik');
    }
    if ((assessment['vocabularyScore'] as num? ?? 0) < 60) {
      improvements.add("So'z boyligi");
    }
    return improvements;
  }
}
