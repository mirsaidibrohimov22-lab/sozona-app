// QO'YISH: lib/features/student/quiz/data/models/quiz_model.dart
// So'zona — Quiz Firestore modeli

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';

class QuizModel extends Quiz {
  const QuizModel({
    required super.id,
    required super.title,
    super.description,
    required super.language,
    required super.level,
    required super.topic,
    required super.creatorId,
    super.creatorType,
    super.classId,
    super.isPublished,
    super.generatedByAi,
    required super.questions,
    required super.totalPoints,
    required super.passingScore,
    super.timeLimitSeconds,
    super.attemptCount,
    super.averageScore,
    super.tags,
    required super.createdAt,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final data = d['data'] as Map<String, dynamic>? ?? {};
    final rawQs = data['questions'] as List<dynamic>? ?? [];

    final questions = rawQs.map((q) {
      final m = q as Map<String, dynamic>;
      return QuizQuestion(
        id: m['id'] as String? ?? '',
        type: _parseType(m['type'] as String? ?? 'mcq'),
        question: m['question'] as String? ?? '',
        options: List<String>.from(m['options'] as List? ?? []),
        correctAnswer: m['correctAnswer'] as String? ?? '',
        explanation: m['explanation'] as String? ?? '',
        points: m['points'] as int? ?? 10,
        timeLimitSeconds: m['timeLimit'] as int? ?? 30,
      );
    }).toList();

    return QuizModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String?,
      language: d['language'] as String? ?? 'en',
      level: d['level'] as String? ?? 'A1',
      topic: d['topic'] as String? ?? '',
      creatorId: d['creatorId'] as String? ?? '',
      creatorType: d['creatorType'] as String? ?? 'ai',
      classId: d['classId'] as String?,
      isPublished: d['isPublished'] as bool? ?? false,
      generatedByAi: d['generatedByAi'] as bool? ?? true,
      questions: questions,
      totalPoints: data['totalPoints'] as int? ?? 0,
      passingScore: data['passingScore'] as int? ?? 0,
      timeLimitSeconds: data['timeLimit'] as int? ?? 300,
      attemptCount: d['attemptCount'] as int? ?? 0,
      averageScore: (d['averageScore'] as num?)?.toDouble() ?? 0,
      tags: List<String>.from(d['tags'] as List? ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static QuestionType _parseType(String t) {
    switch (t) {
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_blank':
        return QuestionType.fillBlank;
      case 'artikel':
        return QuestionType.artikel;
      default:
        return QuestionType.mcq;
    }
  }
}
