// QO'YISH: lib/features/student/quiz/domain/entities/quiz.dart
// So'zona — Quiz entity

import 'package:equatable/equatable.dart';

enum QuestionType { mcq, trueFalse, fillBlank, artikel }

class QuizQuestion extends Equatable {
  final String id;
  final QuestionType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final int points;
  final int timeLimitSeconds;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.points = 10,
    this.timeLimitSeconds = 30,
  });

  // Convenience getters (QuestionWidget uchun)
  bool get hasAudio => false; // audio support keyingi versiyada
  bool get hasImage => false; // image support keyingi versiyada
  String? get imageUrl => null;
  String? get audioUrl => null;
  int get difficulty => 3; // Default difficulty

  String get typeLabel {
    switch (type) {
      case QuestionType.mcq:
        return "Ko'p tanlovli";
      case QuestionType.trueFalse:
        return "Ha/Yo'q";
      case QuestionType.fillBlank:
        return "Bo'sh to'ldirish";
      case QuestionType.artikel:
        return 'Artikel';
    }
  }

  @override
  List<Object?> get props => [id, question, correctAnswer];
}

class Quiz extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String language;
  final String level;
  final String topic;
  final String creatorId;
  final String creatorType; // "teacher" | "student" | "ai"
  final String? classId;
  final bool isPublished;
  final bool generatedByAi;
  final List<QuizQuestion> questions;
  final int totalPoints;
  final int passingScore;
  final int timeLimitSeconds;
  final int attemptCount;
  final double averageScore;
  final List<String> tags;
  final DateTime createdAt;

  const Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.language,
    required this.level,
    required this.topic,
    required this.creatorId,
    this.creatorType = 'ai',
    this.classId,
    this.isPublished = false,
    this.generatedByAi = true,
    required this.questions,
    required this.totalPoints,
    required this.passingScore,
    this.timeLimitSeconds = 300,
    this.attemptCount = 0,
    this.averageScore = 0,
    this.tags = const [],
    required this.createdAt,
  });

  // === UI Getter'lar ===
  int get totalQuestions => questions.length;

  String get languageLabel {
    switch (language.toLowerCase()) {
      case 'english':
        return '🇬🇧 Ingliz';
      case 'deutsch':
      case 'german':
        return '🇩🇪 Nemis';
      default:
        return language;
    }
  }

  String get difficultyLabel {
    switch (level.toLowerCase()) {
      case 'beginner':
        return '🟢 Boshlang\'ich';
      case 'intermediate':
        return '🟡 O\'rta';
      case 'advanced':
        return '🔴 Yuqori';
      default:
        return level;
    }
  }

  String get timeLimitFormatted {
    if (timeLimitSeconds < 60) return '$timeLimitSeconds sek';
    final m = timeLimitSeconds ~/ 60;
    final s = timeLimitSeconds % 60;
    return s == 0 ? '$m daq' : '$m daq $s sek';
  }

  bool get isTeacherCreated => creatorType == 'teacher';
  bool get isStudentQuiz => creatorType == 'student';

  String get creatorLabel {
    if (isTeacherCreated) return '👨‍🏫 O\'qituvchi';
    if (isStudentQuiz) return '👨‍🎓 O\'quvchi';
    return '🤖 AI';
  }

  int get questionCount => questions.length;

  @override
  List<Object?> get props => [id, title, language, level];
}
