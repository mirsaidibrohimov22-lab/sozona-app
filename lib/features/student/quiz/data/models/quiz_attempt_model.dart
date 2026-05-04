// lib/features/student/quiz/data/models/quiz_attempt_model.dart
// So'zona — Quiz urinish modeli (null-safe)
// ✅ FIX: questionText qo'shildi — AI murabbiy uchun savol matni

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz_attempt.dart';

// ─── QuizAnswerModel ───────────────────────────────────────────────────────

class QuizAnswerModel extends QuizAnswer {
  const QuizAnswerModel({
    required super.questionId,
    super.questionText = '', // ✅ YANGI
    required super.userAnswer,
    required super.correctAnswer,
    required super.isCorrect,
    required super.timeSpentSeconds,
    required super.points,
  });

  factory QuizAnswerModel.fromMap(Map<String, dynamic> map) {
    return QuizAnswerModel(
      questionId: (map['questionId'] as String?) ?? '',
      questionText: (map['questionText'] as String?) ?? '', // ✅ YANGI
      userAnswer: (map['userAnswer'] as String?) ?? '',
      correctAnswer: (map['correctAnswer'] as String?) ?? '',
      isCorrect: (map['isCorrect'] as bool?) ?? false,
      timeSpentSeconds: (map['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      points: (map['points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'questionId': questionId,
        'questionText': questionText, // ✅ YANGI
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'timeSpentSeconds': timeSpentSeconds,
        'points': points,
      };

  factory QuizAnswerModel.fromEntity(QuizAnswer entity) {
    return QuizAnswerModel(
      questionId: entity.questionId,
      questionText: entity.questionText, // ✅ YANGI
      userAnswer: entity.userAnswer,
      correctAnswer: entity.correctAnswer,
      isCorrect: entity.isCorrect,
      timeSpentSeconds: entity.timeSpentSeconds,
      points: entity.points,
    );
  }
}

// ─── QuizAttemptModel ─────────────────────────────────────────────────────

class QuizAttemptModel extends QuizAttempt {
  const QuizAttemptModel({
    required super.id,
    required super.userId,
    required super.quizId,
    required super.quizTitle,
    super.classId,
    required super.score,
    required super.maxScore,
    required super.percentage,
    required super.passed,
    required super.timeSpentSeconds,
    required super.answers,
    super.xpEarned = 0,
    required super.createdAt,
    super.completedAt,
  });

  // ─── Firestore → Model ────────────────────────────────────────────────────

  factory QuizAttemptModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return QuizAttemptModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      quizId: (data['quizId'] as String?) ?? '',
      quizTitle: (data['quizTitle'] as String?) ?? '',
      classId: data['classId'] as String?,
      score: (data['score'] as num?)?.toInt() ?? 0,
      maxScore: (data['maxScore'] as num?)?.toInt() ?? 0,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: (data['passed'] as bool?) ?? false,
      timeSpentSeconds: (data['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      answers: ((data['answers'] as List<dynamic>?) ?? [])
          .map((e) => QuizAnswerModel.fromMap(
                (e as Map<String, dynamic>?) ?? {},
              ))
          .toList(),
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // ─── Map → Model (SQLite / local) ─────────────────────────────────────────

  factory QuizAttemptModel.fromMap(Map<String, dynamic> map) {
    return QuizAttemptModel(
      id: (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      quizId: (map['quizId'] as String?) ?? '',
      quizTitle: (map['quizTitle'] as String?) ?? '',
      classId: map['classId'] as String?,
      score: (map['score'] as num?)?.toInt() ?? 0,
      maxScore: (map['maxScore'] as num?)?.toInt() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      passed: (map['passed'] as bool?) ?? false,
      timeSpentSeconds: (map['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      answers: ((map['answers'] as List<dynamic>?) ?? [])
          .map((e) => QuizAnswerModel.fromMap(
                (e as Map<String, dynamic>?) ?? {},
              ))
          .toList(),
      xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  // ─── Model → Firestore ────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'quizId': quizId,
        'quizTitle': quizTitle,
        if (classId != null) 'classId': classId,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'passed': passed,
        'timeSpentSeconds': timeSpentSeconds,
        'answers':
            answers.map((a) => QuizAnswerModel.fromEntity(a).toMap()).toList(),
        'xpEarned': xpEarned,
        'createdAt': Timestamp.fromDate(createdAt),
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
      };

  // ─── Model → Map (SQLite / local) ─────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'quizId': quizId,
        'quizTitle': quizTitle,
        'classId': classId,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'passed': passed ? 1 : 0,
        'timeSpentSeconds': timeSpentSeconds,
        'answers':
            answers.map((a) => QuizAnswerModel.fromEntity(a).toMap()).toList(),
        'xpEarned': xpEarned,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  // ─── Entity → Model ───────────────────────────────────────────────────────

  factory QuizAttemptModel.fromEntity(QuizAttempt entity) {
    return QuizAttemptModel(
      id: entity.id,
      userId: entity.userId,
      quizId: entity.quizId,
      quizTitle: entity.quizTitle,
      classId: entity.classId,
      score: entity.score,
      maxScore: entity.maxScore,
      percentage: entity.percentage,
      passed: entity.passed,
      timeSpentSeconds: entity.timeSpentSeconds,
      answers: entity.answers,
      xpEarned: entity.xpEarned,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
    );
  }
}
