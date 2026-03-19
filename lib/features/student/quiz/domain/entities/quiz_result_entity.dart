// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Quiz Result Entity
// QO'YISH: lib/features/student/quiz/domain/entities/quiz_result_entity.dart
// ═══════════════════════════════════════════════════════════════
//
// Bu fayl — Quiz natijasini saqlash uchun entity.
// O'quvchi testni topshirgach, natija shu yerda saqlanadi.
//
// Bolaga tushuntirish:
// Imtihon topshirgach — varaqangizga baho qo'yiladi.
// Bu fayl — o'sha baho va javoblar yozilgan varaq.
// ═══════════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

/// Quiz Result Entity — test natijasi
class QuizResultEntity extends Equatable {
  /// Natija ID
  final String id;

  /// Quiz ID
  final String quizId;

  /// O'quvchi ID
  final String studentId;

  /// Jami savol soni
  final int totalQuestions;

  /// To'g'ri javoblar soni
  final int correctAnswers;

  /// Noto'g'ri javoblar soni
  final int wrongAnswers;

  /// Ball (foizda, 0-100)
  final double scorePercentage;

  /// O'tgan/O'tmagan
  final bool isPassed;

  /// Har bir savolga berilgan javoblar
  /// Map format: {'q1': 'goes', 'q2': 'true', ...}
  final Map<String, String> userAnswers;

  /// Sarflangan vaqt (sekundda)
  final int timeSpent;

  /// Topshirish sanasi
  final DateTime completedAt;

  /// Quiz qaysi tilga tegishli?
  final String language;

  /// Qiyinlik darajasi
  final String level;

  /// XP (experience points) — o'yin tizimi uchun
  final int xpEarned;

  /// Streak saqlanganmi? (ketma-ket kunlar)
  final bool streakMaintained;

  const QuizResultEntity({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.scorePercentage,
    required this.isPassed,
    required this.userAnswers,
    required this.timeSpent,
    required this.completedAt,
    required this.language,
    required this.level,
    this.xpEarned = 0,
    this.streakMaintained = false,
  });

  // ═══════════════════════════════════
  // Qulaylik metodlari
  // ═══════════════════════════════════

  /// Natija emoji
  String get resultEmoji {
    if (scorePercentage >= 90) return '🏆'; // A'lo
    if (scorePercentage >= 80) return '🥇'; // Juda yaxshi
    if (scorePercentage >= 70) return '👏'; // Yaxshi
    if (scorePercentage >= 60) return '👍'; // O'rtacha
    return '😕'; // Yaxshilanishi kerak
  }

  /// Baho harfi
  String get gradeLabel {
    if (scorePercentage >= 90) return 'A+';
    if (scorePercentage >= 80) return 'A';
    if (scorePercentage >= 70) return 'B';
    if (scorePercentage >= 60) return 'C';
    if (scorePercentage >= 50) return 'D';
    return 'F';
  }

  /// Sarflangan vaqt (formatlangan)
  String get timeSpentFormatted {
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')} daqiqa';
    }
    return '$seconds soniya';
  }

  /// Motivatsion xabar
  String get motivationMessage {
    if (scorePercentage >= 90) {
      return 'Ajoyib! Siz zo\'rsiz! 🎉';
    } else if (scorePercentage >= 80) {
      return 'Juda yaxshi! Davom eting! 💪';
    } else if (scorePercentage >= 70) {
      return 'Yaxshi natija! Oldinga! 👏';
    } else if (scorePercentage >= 60) {
      return 'Yaxshi harakat! Yana urinib ko\'ring! 👍';
    } else {
      return 'Mashq qiling, muvaffaqiyat sizniki! 💪';
    }
  }

  /// To'g'ri javoblar foizi
  double get correctPercentage {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 100;
  }

  /// Noto'g'ri javoblar foizi
  double get wrongPercentage {
    if (totalQuestions == 0) return 0;
    return (wrongAnswers / totalQuestions) * 100;
  }

  // ═══════════════════════════════════
  // CopyWith
  // ═══════════════════════════════════
  QuizResultEntity copyWith({
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
    return QuizResultEntity(
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

  // ═══════════════════════════════════
  // Equatable
  // ═══════════════════════════════════
  @override
  List<Object?> get props => [
        id,
        quizId,
        studentId,
        totalQuestions,
        correctAnswers,
        wrongAnswers,
        scorePercentage,
        isPassed,
        userAnswers,
        timeSpent,
        completedAt,
        language,
        level,
        xpEarned,
        streakMaintained,
      ];
}
