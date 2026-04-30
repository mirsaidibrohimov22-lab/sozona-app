import 'dart:async';
// lib/features/student/listening/data/datasources/listening_remote_datasource.dart
// So'zona — Listening Remote DataSource
// ✅ 1-KUN FIX (K9): hardcoded collection nomi → FirestorePaths.listeningExercises
//    Endi collection nomi faqat bitta joyda — firestore_paths.dart da boshqariladi
//    Oldin: static const String listeningCollection = 'listening_exercises'; (lokal)
//    Endi: FirestorePaths.listeningExercises (markaziy)
// ✅ v2.0: AI orqali listening yaratish (generateListening Cloud Function)
// ✅ v2.0: TTS orqali audio o'qish imkoniyati
// ✅ v2.0: Activity tracking qo'shildi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/core/constants/firestore_paths.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/services/member_progress_service.dart';
import 'package:my_first_app/features/student/listening/data/models/listening_model.dart';

abstract class ListeningRemoteDataSource {
  Future<List<ListeningModel>> getListeningExercises({
    String? language,
    String? level,
    String? topic,
  });

  Future<ListeningModel> getListeningDetail(String exerciseId);

  /// AI orqali listening yaratish
  Future<ListeningModel> generateListeningExercise({
    required String language,
    required String level,
    required String topic,
    int questionCount,
  });

  Future<Map<String, dynamic>> submitListeningAnswers({
    required String exerciseId,
    required String studentId,
    required Map<String, String> answers,
    required int timeSpent,
  });
}

class ListeningRemoteDataSourceImpl implements ListeningRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseFunctions? functions;

  // ✅ 1-KUN FIX (K9): Markaziy path ishlatiladi
  // Endi collection nomi FirestorePaths.listeningExercises dan olinadi
  // Bu firestore.rules dagi 'listening_exercises' bilan 100% mos

  ListeningRemoteDataSourceImpl({
    required this.firestore,
    this.functions,
  });

  FirebaseFunctions get _fn =>
      functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<List<ListeningModel>> getListeningExercises({
    String? language,
    String? level,
    String? topic,
  }) async {
    try {
      return await _tryCompositeQuery(
        language: language,
        level: level,
        topic: topic,
      );
    } on FirebaseException catch (e) {
      if (e.message?.contains('requires an index') == true ||
          e.code == 'failed-precondition') {
        debugPrint('⚠️ Composite index topilmadi, fallback ishlatiladi');
        return await _fallbackQuery(
          language: language,
          level: level,
          topic: topic,
        );
      }
      throw ServerException(message: 'Firebase xatosi: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Listening yuklashda xatolik: $e');
    }
  }

  Future<List<ListeningModel>> _tryCompositeQuery({
    String? language,
    String? level,
    String? topic,
  }) async {
    // ✅ 1-KUN FIX: FirestorePaths.listeningExercises ishlatildi
    Query query = firestore
        .collection(FirestorePaths.listeningExercises)
        .where('isActive', isEqualTo: true);

    if (language != null) {
      query = query.where('language', isEqualTo: language);
    }
    if (level != null) {
      query = query.where('level', isEqualTo: level);
    }
    if (topic != null) {
      query = query.where('topic', isEqualTo: topic);
    }

    query = query.orderBy('createdAt', descending: true);
    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ListeningModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();
  }

  Future<List<ListeningModel>> _fallbackQuery({
    String? language,
    String? level,
    String? topic,
  }) async {
    // ✅ 1-KUN FIX: FirestorePaths.listeningExercises ishlatildi
    final snapshot = await firestore
        .collection(FirestorePaths.listeningExercises)
        .where('isActive', isEqualTo: true)
        .get();

    var results = snapshot.docs
        .map((doc) => ListeningModel.fromFirestore(
              doc.data(),
              doc.id,
            ))
        .toList();

    if (language != null) {
      results = results.where((e) => e.language == language).toList();
    }
    if (level != null) {
      results = results.where((e) => e.level == level).toList();
    }
    if (topic != null) {
      results = results.where((e) => e.topic == topic).toList();
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<ListeningModel> getListeningDetail(String exerciseId) async {
    try {
      // 1. Avval listening_exercises collectiondan qidirish
      final doc = await firestore
          .collection(FirestorePaths.listeningExercises)
          .doc(exerciseId)
          .get();

      if (doc.exists) {
        return ListeningModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }

      // 2. O'qituvchi yuborgan kontent — root 'content' collectiondan qidirish
      final contentDoc =
          await firestore.collection('content').doc(exerciseId).get();

      if (contentDoc.exists) {
        final data = contentDoc.data() as Map<String, dynamic>;
        // content collectionidagi ma'lumotni ListeningModel ga moslash
        return ListeningModel.fromFirestore(
          {
            ...data,
            // 'data' ichidagi fieldlarni yuqoriga ko'tarish
            if (data['data'] is Map) ...(data['data'] as Map<String, dynamic>),
          },
          contentDoc.id,
        );
      }

      // 3. classes subcollectionlardan qidirish
      final classesSnap = await firestore
          .collection('classes')
          .where('isActive', isEqualTo: true)
          .get();

      for (final classDoc in classesSnap.docs) {
        final subDoc = await firestore
            .collection('classes')
            .doc(classDoc.id)
            .collection('content')
            .doc(exerciseId)
            .get();

        if (subDoc.exists) {
          final data = subDoc.data() as Map<String, dynamic>;
          return ListeningModel.fromFirestore(
            {
              ...data,
              if (data['data'] is Map)
                ...(data['data'] as Map<String, dynamic>),
            },
            subDoc.id,
          );
        }
      }

      throw const ServerException(message: 'Listening mashq topilmadi');
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Firebase xatosi: ${e.message}');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Listening detail yuklanmadi: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AI orqali listening yaratish
  // Transcript + savollar AI yaratadi
  // Audio → Flutter TTS orqali o'qiladi (tts_service.dart)
  // ═══════════════════════════════════════════════════════════════

  @override
  Future<ListeningModel> generateListeningExercise({
    required String language,
    required String level,
    required String topic,
    int questionCount = 5,
  }) async {
    try {
      final callable = _fn.httpsCallable(
        ApiEndpoints.generateListening,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );

      final result = await callable.call({
        'language': language,
        'level': level,
        'topic': topic,
        'questionCount': questionCount,
        'duration': 60,
      });

      final data = result.data as Map<String, dynamic>;

      // Transcript dan listening model yaratish
      final transcript = data['transcript'] as String? ?? '';
      final wordCount = transcript.split(RegExp(r'\s+')).length;
      final estimatedDuration = (wordCount / 2.5).round();

      // ✅ 1-KUN FIX: FirestorePaths.listeningExercises ishlatildi
      final docRef =
          await firestore.collection(FirestorePaths.listeningExercises).add({
        'title': 'AI Listening: $topic',
        'description': '$level darajasida $topic mavzusida listening mashq',
        'audioUrl': '',
        'useTts': true,
        'transcript': transcript,
        'duration': estimatedDuration,
        'language': language,
        'level': level,
        'topic': topic,
        'isActive': true,
        'isTeacherCreated': false,
        'createdBy': 'ai',
        'questions': (data['questions'] as List?)
                ?.map((q) => q as Map<String, dynamic>)
                .toList() ??
            [],
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': data['metadata'],
      });

      return ListeningModel.fromFirestore({
        'title': 'AI Listening: $topic',
        'description': '$level darajasida $topic mavzusida listening mashq',
        'audioUrl': '',
        'useTts': true,
        'transcript': transcript,
        'duration': estimatedDuration,
        'language': language,
        'level': level,
        'topic': topic,
        'isActive': true,
        'isTeacherCreated': false,
        'createdBy': 'ai',
        'questions': data['questions'] ?? [],
        'createdAt': Timestamp.now(),
      }, docRef.id);
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(
        message: 'Listening yaratish xatosi: ${e.message}',
      );
    } catch (e) {
      throw ServerException(message: 'Listening yaratish xatosi: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // submitListeningAnswers + Activity Tracking
  // ═══════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> submitListeningAnswers({
    required String exerciseId,
    required String studentId,
    required Map<String, String> answers,
    required int timeSpent,
  }) async {
    try {
      final exercise = await getListeningDetail(exerciseId);

      int correctAnswers = 0;
      int wrongAnswers = 0;
      final wrongItems = <String>[];

      for (final question in exercise.questions) {
        final userAnswer = answers[question.id];
        if (userAnswer != null && question.isCorrect(userAnswer)) {
          correctAnswers++;
        } else {
          wrongAnswers++;
          wrongItems.add(question.question);
        }
      }

      final totalQuestions = exercise.questions.length;
      final scorePercentage =
          totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;

      // ✅ 1-KUN FIX: FirestorePaths.listeningResults ishlatildi
      await firestore.collection(FirestorePaths.listeningResults).add({
        'exerciseId': exerciseId,
        'studentId': studentId,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'scorePercentage': scorePercentage,
        'answers': answers,
        'timeSpent': timeSpent,
        'completedAt': FieldValue.serverTimestamp(),
        'language': exercise.language,
        'level': exercise.level,
      });

      // Activity tracking
      try {
        final callable = _fn.httpsCallable(
          ApiEndpoints.recordActivity,
          options: HttpsCallableOptions(timeout: ApiEndpoints.defaultTimeout),
        );

        await callable.call({
          'skillType': 'listening',
          'topic': exercise.topic,
          'difficulty': 'medium',
          'correctAnswers': correctAnswers,
          'wrongAnswers': wrongAnswers,
          'responseTime': timeSpent,
          'vocabularyUsed': <String>[],
          'grammarErrors': wrongItems,
          'language': exercise.language,
          'level': exercise.level,
          'scorePercent': scorePercentage,
          'weakItems': wrongItems,
          'strongItems': <String>[],
          'contentId': exerciseId,
        });
      } catch (_) {
        // Activity saqlash xatosi sessiyani buzmaydi
      }

      // ✅ FIX: Member progress yangilash
      await MemberProgressService.instance.recordAttempt(
        userId: studentId,
        scorePercent: scorePercentage,
        skillType: 'listening',
      );

      // ✅ YANGI: AI Murabbiy — xato yozish
      if (scorePercentage < 80 && exerciseId.isNotEmpty) {
        unawaited(_fn.httpsCallable('recordMistake').call({
          'contentId': exerciseId,
          'contentType': 'listening',
          'userAnswer': wrongItems.isNotEmpty ? wrongItems.first : '',
          'correctAnswer': '',
          'scorePercent': scorePercentage,
          'language': exercise.language,
        }));
      }

      return {
        'totalCount': totalQuestions,
        'correctCount': correctAnswers,
        'wrongCount': wrongAnswers,
        'scorePercentage': scorePercentage,
      };
    } on FirebaseException catch (e) {
      throw ServerException(message: 'Firebase xatosi: ${e.message}');
    } catch (e) {
      throw ServerException(message: 'Javoblarni yuborishda xatolik: $e');
    }
  }
}
