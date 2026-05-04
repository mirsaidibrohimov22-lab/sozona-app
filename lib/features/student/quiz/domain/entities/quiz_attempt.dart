// lib/features/student/quiz/domain/entities/quiz_attempt.dart
// So'zona — Quiz urinish entity
// ✅ FIX: questionText qo'shildi — AI murabbiy savol matnini ko'ra olsin

import 'package:equatable/equatable.dart';

class QuizAnswer extends Equatable {
  final String questionId;
  final String questionText; // ✅ YANGI: savol matni ("She ___ to school")
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int timeSpentSeconds;
  final int points;

  const QuizAnswer({
    required this.questionId,
    this.questionText = '', // ✅ default — eski kod bilan mos
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.points,
  });

  @override
  List<Object?> get props => [questionId, userAnswer, isCorrect];
}

class QuizAttempt extends Equatable {
  final String id;
  final String userId;
  final String quizId;
  final String quizTitle;
  final String? classId;
  final int score;
  final int maxScore;
  final double percentage;
  final bool passed;
  final int timeSpentSeconds;
  final List<QuizAnswer> answers;
  final int xpEarned;
  final DateTime createdAt;
  final DateTime? completedAt;

  const QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.quizTitle,
    this.classId,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.passed,
    required this.timeSpentSeconds,
    required this.answers,
    this.xpEarned = 0,
    required this.createdAt,
    this.completedAt,
  });

  List<QuizAnswer> get wrongAnswers =>
      answers.where((a) => !a.isCorrect).toList();

  @override
  List<Object?> get props => [id, userId, quizId, score];
}
