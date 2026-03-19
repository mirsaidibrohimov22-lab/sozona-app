// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Quiz Result Model
// QO'YISH: lib/features/student/quiz/data/models/quiz_result_model.dart
// ═══════════════════════════════════════════════════════════════
//
// Bu fayl — Quiz Result Model (Data layer).
// Natijalarni Firebase'ga saqlash va o'qish uchun.
//
// Bolaga tushuntirish:
// Imtihon topshirgach — natijangiz Firebase'ga saqlanadi.
// Model — o'sha natijani JSON formatga o'girib yuboradi.
// ═══════════════════════════════════════════════════════════════

import 'package:my_first_app/features/student/quiz/domain/entities/quiz_result_entity.dart';

/// Quiz Result Model — JSON serialization bilan
class QuizResultModel extends QuizResultEntity {
  const QuizResultModel({
    required super.id,
    required super.quizId,
    required super.studentId,
    required super.totalQuestions,
    required super.correctAnswers,
    required super.wrongAnswers,
    required super.scorePercentage,
    required super.isPassed,
    required super.userAnswers,
    required super.timeSpent,
    required super.completedAt,
    required super.language,
    required super.level,
    super.xpEarned = 0,
    super.streakMaintained = false,
  });

  // ═══════════════════════════════════
  // JSON → Model (Firestore'dan o'qish)
  // ═══════════════════════════════════

  /// Firestore document'dan QuizResultModel yaratish
  factory QuizResultModel.fromFirestore(
    Map<String, dynamic> json,
    String id,
  ) {
    return QuizResultModel(
      id: id,
      quizId: json['quizId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      wrongAnswers: json['wrongAnswers'] as int? ?? 0,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0.0,
      isPassed: json['isPassed'] as bool? ?? false,
      userAnswers: Map<String, String>.from(
        json['userAnswers'] as Map<String, dynamic>? ?? {},
      ),
      timeSpent: json['timeSpent'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : DateTime.now(),
      language: json['language'] as String? ?? 'english',
      level: json['level'] as String? ?? 'beginner',
      xpEarned: json['xpEarned'] as int? ?? 0,
      streakMaintained: json['streakMaintained'] as bool? ?? false,
    );
  }

  /// JSON object'dan QuizResultModel yaratish
  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      id: json['id'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      wrongAnswers: json['wrongAnswers'] as int? ?? 0,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0.0,
      isPassed: json['isPassed'] as bool? ?? false,
      userAnswers: Map<String, String>.from(
        json['userAnswers'] as Map<String, dynamic>? ?? {},
      ),
      timeSpent: json['timeSpent'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
      language: json['language'] as String? ?? 'english',
      level: json['level'] as String? ?? 'beginner',
      xpEarned: json['xpEarned'] as int? ?? 0,
      streakMaintained: json['streakMaintained'] as bool? ?? false,
    );
  }

  // ═══════════════════════════════════
  // Model → JSON (Firestore'ga yozish)
  // ═══════════════════════════════════

  /// QuizResultModel'ni Firestore uchun JSON'ga aylantirish
  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'scorePercentage': scorePercentage,
      'isPassed': isPassed,
      'userAnswers': userAnswers,
      'timeSpent': timeSpent,
      'completedAt': completedAt.millisecondsSinceEpoch,
      'language': language,
      'level': level,
      'xpEarned': xpEarned,
      'streakMaintained': streakMaintained,
    };
  }

  /// QuizResultModel'ni oddiy JSON'ga aylantirish
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'scorePercentage': scorePercentage,
      'isPassed': isPassed,
      'userAnswers': userAnswers,
      'timeSpent': timeSpent,
      'completedAt': completedAt.toIso8601String(),
      'language': language,
      'level': level,
      'xpEarned': xpEarned,
      'streakMaintained': streakMaintained,
    };
  }

  // ═══════════════════════════════════
  // Entity → Model
  // ═══════════════════════════════════

  /// QuizResultEntity'dan QuizResultModel yaratish
  factory QuizResultModel.fromEntity(QuizResultEntity entity) {
    return QuizResultModel(
      id: entity.id,
      quizId: entity.quizId,
      studentId: entity.studentId,
      totalQuestions: entity.totalQuestions,
      correctAnswers: entity.correctAnswers,
      wrongAnswers: entity.wrongAnswers,
      scorePercentage: entity.scorePercentage,
      isPassed: entity.isPassed,
      userAnswers: entity.userAnswers,
      timeSpent: entity.timeSpent,
      completedAt: entity.completedAt,
      language: entity.language,
      level: entity.level,
      xpEarned: entity.xpEarned,
      streakMaintained: entity.streakMaintained,
    );
  }

  // ═══════════════════════════════════
  // CopyWith (override)
  // ═══════════════════════════════════
  @override
  QuizResultModel copyWith({
    String? id,
    String? quizId,
    String? studentId,
    int? totalQuestions,
    int? correctAnswers,
    int? wrongAnswers,
    double? scorePercentage,
    bool? isPassed,
    Map<String, String>? userAnswers,
    int? timeSpent,
    DateTime? completedAt,
    String? language,
    String? level,
    int? xpEarned,
    bool? streakMaintained,
  }) {
    return QuizResultModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      scorePercentage: scorePercentage ?? this.scorePercentage,
      isPassed: isPassed ?? this.isPassed,
      userAnswers: userAnswers ?? this.userAnswers,
      timeSpent: timeSpent ?? this.timeSpent,
      completedAt: completedAt ?? this.completedAt,
      language: language ?? this.language,
      level: level ?? this.level,
      xpEarned: xpEarned ?? this.xpEarned,
      streakMaintained: streakMaintained ?? this.streakMaintained,
    );
  }
}
