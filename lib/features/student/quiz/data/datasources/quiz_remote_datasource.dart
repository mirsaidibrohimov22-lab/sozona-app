// lib/features/student/quiz/data/datasources/quiz_remote_datasource.dart
// So'zona — Quiz Firebase datasource
// ✅ FIX: getQuizzes endi foydalanuvchi o'z quizlarini ham ko'radi
// ✅ YANGI: deleteQuiz() metodi qo'shildi
// ✅ YANGI: createStudentQuiz grammar va questionCount parametrlarini qabul qiladi

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/core/constants/firestore_paths.dart';
import 'package:my_first_app/core/error/exceptions.dart';
import 'package:my_first_app/core/services/member_progress_service.dart';
import 'package:my_first_app/core/utils/json_validator.dart';
import 'package:my_first_app/features/student/quiz/data/models/quiz_model.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz_attempt.dart';

abstract class QuizRemoteDataSource {
  Future<List<QuizModel>> getQuizzes({
    required String userId,
    required String language,
    required String level,
    String? classId,
  });
  Future<QuizModel> getQuizDetail(String quizId);
  Future<QuizModel> getAiRecommendedQuiz({
    required String userId,
    required String language,
    required String level,
  });
  Future<QuizModel> createStudentQuiz({
    required String userId,
    required String language,
    required String level,
    required String topic,
    String grammar,
    int questionCount,
  });
  Future<void> deleteQuiz(String quizId);
  Future<QuizAttempt> submitQuiz({
    required String userId,
    required String quizId,
    required String quizTitle,
    String? classId,
    required List<QuizAnswer> answers,
    required int timeSpentSeconds,
    required int maxScore,
  });
  Future<List<QuizAttempt>> getAttemptHistory(String userId);
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final _uuid = const Uuid();

  QuizRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  CollectionReference get _quizzesRef =>
      _firestore.collection(FirestorePaths.quizzes);

  CollectionReference get _attemptsRef =>
      _firestore.collection(FirestorePaths.attempts);

  CollectionReference get _usersRef =>
      _firestore.collection(FirestorePaths.users);

  // ─── QUIZLARNI OLISH ───
  // ✅ FIX: ikkita so'rov — 1) nashr qilingan, 2) foydalanuvchi o'z quizlari
  @override
  Future<List<QuizModel>> getQuizzes({
    required String userId,
    required String language,
    required String level,
    String? classId,
  }) async {
    try {
      // 1) Nashr qilingan quizlar (o'qituvchi yoki umumiy)
      final publishedFuture = _getPublishedQuizzes(
        language: language,
        classId: classId,
      );

      // 2) Foydalanuvchi o'zi yaratgan quizlar (nashr qilinmagan ham)
      final myQuizzesFuture = _getMyQuizzes(userId: userId);

      final results = await Future.wait([publishedFuture, myQuizzesFuture]);
      final published = results[0];
      final mine = results[1];

      // Birlashtirish va takrorlanganlarni olib tashlash
      final merged = <String, QuizModel>{};
      for (final q in [...published, ...mine]) {
        merged[q.id] = q;
      }

      final all = merged.values.toList();
      // O'qituvchi quizlari oldin, keyin o'z quizlari
      all.sort((a, b) {
        // O'qituvchi quizlari birinchi
        if (a.creatorType == 'teacher' && b.creatorType != 'teacher') return -1;
        if (a.creatorType != 'teacher' && b.creatorType == 'teacher') return 1;
        // Keyin yangilikka qarab
        return b.createdAt.compareTo(a.createdAt);
      });

      return all;
    } catch (e) {
      throw ServerException(message: 'Quizlar yuklanmadi: $e');
    }
  }

  Future<List<QuizModel>> _getPublishedQuizzes({
    required String language,
    String? classId,
  }) async {
    try {
      Query query = _quizzesRef
          .where('type', isEqualTo: 'quiz')
          .where('language', isEqualTo: language)
          .where('isPublished', isEqualTo: true);

      if (classId != null) query = query.where('classId', isEqualTo: classId);

      final snap = await query.limit(30).get();
      final results = snap.docs.map(QuizModel.fromFirestore).toList();
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('🔴 [QuizDS] Composite index yo\'q, fallback: ${e.message}');
        try {
          final snap = await _quizzesRef
              .where('isPublished', isEqualTo: true)
              .limit(30)
              .get();
          return snap.docs
              .map(QuizModel.fromFirestore)
              .where((q) => q.language == language)
              .toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    }
  }

  Future<List<QuizModel>> _getMyQuizzes({required String userId}) async {
    try {
      final snap = await _quizzesRef
          .where('creatorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snap.docs.map(QuizModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        try {
          final snap = await _quizzesRef
              .where('creatorId', isEqualTo: userId)
              .limit(20)
              .get();
          final results = snap.docs.map(QuizModel.fromFirestore).toList();
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return results;
        } catch (_) {
          return [];
        }
      }
      debugPrint('⚠️ [QuizDS] My quizzes xato: ${e.message}');
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── QUIZ DETAIL ───
  @override
  Future<QuizModel> getQuizDetail(String quizId) async {
    try {
      // 1. Avval root content collectionidan qidirish
      final doc = await _quizzesRef.doc(quizId).get();
      if (doc.exists) return QuizModel.fromFirestore(doc);

      // 2. Root da topilmasa — classes subcollectionlardan qidirish
      // Teacher sinf ga yuborgan kontentlar classes/{id}/content da saqlangan
      final classesSnap = await _firestore
          .collection('classes')
          .where('isActive', isEqualTo: true)
          .get();

      for (final classDoc in classesSnap.docs) {
        final contentDoc = await _firestore
            .collection('classes')
            .doc(classDoc.id)
            .collection('content')
            .doc(quizId)
            .get();
        if (contentDoc.exists) {
          return QuizModel.fromFirestore(contentDoc);
        }
      }

      throw const ServerException(message: 'Quiz topilmadi');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Quiz detail yuklanmadi: \$e');
    }
  }

  // ─── AI TAVSIYA QILINGAN QUIZ ───
  @override
  Future<QuizModel> getAiRecommendedQuiz({
    required String userId,
    required String language,
    required String level,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        ApiEndpoints.generateQuiz,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );
      final result = await callable.call({
        'userId': userId,
        'language': language,
        'level': level,
        'useWeakItems': true,
        'save': false, // AI quiz to'g'ridan-to'g'ri o'ynash uchun
      });
      final data = result.data as Map<String, dynamic>;
      if (!JsonValidator.isValidQuizResponse(data)) {
        throw const ServerException(message: 'AI quiz formati noto\'g\'ri');
      }
      return _buildQuizFromAi(data, userId, language, level);
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(message: 'AI quiz xatoligi: ${e.message}');
    }
  }

  // ─── STUDENT QUIZ YARATISH (grammar va questionCount bilan) ───
  @override
  Future<QuizModel> createStudentQuiz({
    required String userId,
    required String language,
    required String level,
    required String topic,
    String grammar = '',
    int questionCount = 10,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        ApiEndpoints.generateQuiz,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );
      final result = await callable.call({
        'userId': userId,
        'language': language,
        'level': level,
        'topic': topic,
        'grammar': grammar,
        'questionCount': questionCount,
        'save': true, // Firestore ga saqlash
      });
      final data = result.data as Map<String, dynamic>;
      if (!JsonValidator.isValidQuizResponse(data)) {
        throw const ServerException(message: 'AI quiz formati noto\'g\'ri');
      }
      final quiz = _buildQuizFromAi(data, userId, language, level);

      // Agar Cloud Function saqlamagan bo'lsa — Flutter tomondan saqlash
      // (Cloud Function ichida save: true bilan saqlash qiladi)
      return quiz;
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(message: 'Quiz yaratish xatoligi: ${e.message}');
    }
  }

  // ─── QUIZ O'CHIRISH ───
  @override
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _quizzesRef.doc(quizId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: "Quiz o'chirilmadi: ${e.message}");
    } catch (e) {
      throw ServerException(message: "Quiz o'chirilmadi: $e");
    }
  }

  // ─── QUIZ TOPSHIRISH ───
  @override
  Future<QuizAttempt> submitQuiz({
    required String userId,
    required String quizId,
    required String quizTitle,
    String? classId,
    required List<QuizAnswer> answers,
    required int timeSpentSeconds,
    required int maxScore,
  }) async {
    try {
      final score =
          answers.fold(0, (acc, a) => acc + (a.isCorrect ? a.points : 0));
      final pct = maxScore > 0 ? (score / maxScore * 100) : 0.0;
      final passed = pct >= 60;
      final xp = (pct * 0.5).round();

      final attempt = QuizAttempt(
        id: _uuid.v4(),
        userId: userId,
        quizId: quizId,
        quizTitle: quizTitle,
        classId: classId,
        score: score,
        maxScore: maxScore,
        percentage: pct,
        passed: passed,
        timeSpentSeconds: timeSpentSeconds,
        answers: answers,
        xpEarned: xp,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      final batch = _firestore.batch();

      // 1. Attempt saqlash
      batch.set(_attemptsRef.doc(attempt.id), {
        'userId': userId,
        'contentId': quizId,
        'contentType': 'quiz',
        'contentTitle': quizTitle,
        'classId': classId,
        'score': score,
        'maxScore': maxScore,
        'percentage': pct,
        'passed': passed,
        'timeSpent': timeSpentSeconds,
        'xpEarned': xp,
        'answers': answers
            .map(
              (a) => {
                'questionId': a.questionId,
                'userAnswer': a.userAnswer,
                'correctAnswer': a.correctAnswer,
                'isCorrect': a.isCorrect,
                'timeSpent': a.timeSpentSeconds,
                'points': a.points,
              },
            )
            .toList(),
        'createdAt': Timestamp.now(),
        'completedAt': Timestamp.now(),
      });

      // 2. User XP yangilash - set+merge: field bo'lmasa ham ishlaydi
      batch.set(
        _usersRef.doc(userId),
        {
          'totalXp': FieldValue.increment(xp),
          'lastActiveDate': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      // 3. Quiz statistikasini yangilash
      try {
        batch.update(_quizzesRef.doc(quizId), {
          'attemptCount': FieldValue.increment(1),
        });
      } catch (_) {
        // Quiz mavjud emas bo'lsa (adaptive quiz) — o'tkazib yuborish
      }

      await batch.commit();

      // 4. ✅ FIX: Barcha sinflarda member progress yangilash
      // MemberProgressService o'zi Firestore dan o'quvchi sinflarini topadi
      await MemberProgressService.instance.recordAttempt(
        userId: userId,
        scorePercent: pct,
        skillType: 'quiz',
      );

      return attempt;
    } catch (e) {
      throw ServerException(message: 'Quiz natijasi saqlanmadi: $e');
    }
  }

  // ─── ATTEMPT TARIXI ───
  @override
  Future<List<QuizAttempt>> getAttemptHistory(String userId) async {
    try {
      final snap = await _attemptsRef
          .where('userId', isEqualTo: userId)
          .where('contentType', isEqualTo: 'quiz')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final rawA = d['answers'] as List<dynamic>? ?? [];
        final answers = rawA.map((a) {
          final m = a as Map<String, dynamic>;
          return QuizAnswer(
            questionId: m['questionId'] as String? ?? '',
            userAnswer: m['userAnswer'] as String? ?? '',
            correctAnswer: m['correctAnswer'] as String? ?? '',
            isCorrect: m['isCorrect'] as bool? ?? false,
            timeSpentSeconds: m['timeSpent'] as int? ?? 0,
            points: m['points'] as int? ?? 0,
          );
        }).toList();
        return QuizAttempt(
          id: doc.id,
          userId: d['userId'] as String? ?? '',
          quizId: d['contentId'] as String? ?? '',
          quizTitle: d['contentTitle'] as String? ?? '',
          classId: d['classId'] as String?,
          score: d['score'] as int? ?? 0,
          maxScore: d['maxScore'] as int? ?? 0,
          percentage: (d['percentage'] as num?)?.toDouble() ?? 0,
          passed: d['passed'] as bool? ?? false,
          timeSpentSeconds: d['timeSpent'] as int? ?? 0,
          answers: answers,
          xpEarned: d['xpEarned'] as int? ?? 0,
          createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Fallback: orderBy olmagan
        final snap = await _attemptsRef
            .where('userId', isEqualTo: userId)
            .where('contentType', isEqualTo: 'quiz')
            .limit(30)
            .get();
        final results = snap.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return QuizAttempt(
            id: doc.id,
            userId: d['userId'] as String? ?? '',
            quizId: d['contentId'] as String? ?? '',
            quizTitle: d['contentTitle'] as String? ?? '',
            classId: d['classId'] as String?,
            score: d['score'] as int? ?? 0,
            maxScore: d['maxScore'] as int? ?? 0,
            percentage: (d['percentage'] as num?)?.toDouble() ?? 0,
            passed: d['passed'] as bool? ?? false,
            timeSpentSeconds: d['timeSpent'] as int? ?? 0,
            answers: const [],
            xpEarned: d['xpEarned'] as int? ?? 0,
            createdAt:
                (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
          );
        }).toList();
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return results;
      }
      throw ServerException(message: 'Tarix yuklanmadi: ${e.message}');
    }
  }

  // ─── YORDAMCHI METODLAR ───
  QuizModel _buildQuizFromAi(
    Map<String, dynamic> data,
    String userId,
    String language,
    String level,
  ) {
    final rawQs = data['questions'] as List<dynamic>? ?? [];
    final questions = rawQs.map((q) {
      final m = Map<String, dynamic>.from(q as Map);
      return QuizQuestion(
        id: m['id'] as String? ?? _uuid.v4(),
        type: QuestionType.mcq,
        question: m['question'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
        correctAnswer: m['correctAnswer'] as String? ?? '',
        explanation: m['explanation'] as String? ?? '',
        points: (m['points'] as num?)?.toInt() ?? 10,
        timeLimitSeconds: (m['timeLimit'] as num?)?.toInt() ?? 30,
      );
    }).toList();
    final totalPts = questions.fold(0, (acc, q) => acc + q.points);
    return QuizModel(
      id: _uuid.v4(),
      title: data['title'] as String? ?? 'AI Quiz',
      language: language,
      level: level,
      topic: data['topic'] as String? ?? 'General',
      creatorId: userId,
      creatorType: 'ai',
      generatedByAi: true,
      questions: questions,
      totalPoints: totalPts,
      passingScore: (totalPts * 0.6).round(),
      createdAt: DateTime.now(),
    );
  }
}
