// QO'YISH: lib/features/teacher/classes/domain/entities/student_summary.dart
// So'zona — Student xulosasi (Domain Layer)
// O'qituvchi sinfidagi har bir o'quvchi haqida qisqacha ma'lumot

import 'package:equatable/equatable.dart';

/// Sinfdagi o'quvchi haqida qisqacha ma'lumot
///
/// Bolaga tushuntirish:
/// Bu — sinf jurnalining bir qatori. O'quvchining ismi,
/// oxirgi faolligi, o'rtacha bali — hammasi bir joyda.
class StudentSummary extends Equatable {
  /// Firebase UID
  final String userId;

  /// O'quvchi ismi
  final String fullName;

  /// CEFR darajasi
  final String level;

  /// Sinfga qo'shilgan sana
  final DateTime joinedAt;

  /// Oxirgi faollik vaqti
  final DateTime lastActiveAt;

  /// O'rtacha ball (0-100)
  final double averageScore;

  /// Jami urinishlar soni
  final int totalAttempts;

  /// Joriy streak (ketma-ket kunlar)
  final int currentStreak;

  /// Profil rasmi URL (ixtiyoriy)
  final String? avatarUrl;

  /// ✅ YANGI: Har bir skill bo'yicha foiz (0-100)
  /// Masalan: {quiz: 65.0, listening: 40.0, speaking: 80.0, flashcard: 55.0}
  final Map<String, double> skillScores;

  const StudentSummary({
    required this.userId,
    required this.fullName,
    required this.level,
    required this.joinedAt,
    required this.lastActiveAt,
    required this.averageScore,
    required this.totalAttempts,
    required this.currentStreak,
    this.avatarUrl,
    this.skillScores = const {},
  });

  /// Oxirgi 7 kunda faol bo'lganmi?
  bool get isRecentlyActive {
    final diff = DateTime.now().difference(lastActiveAt);
    return diff.inDays <= 7;
  }

  /// Ball darajasi (rang uchun)
  /// 80+ = yaxshi (yashil), 50-79 = o'rta (sariq), <50 = past (qizil)
  ScoreLevel get scoreLevel {
    if (averageScore >= 80) return ScoreLevel.good;
    if (averageScore >= 50) return ScoreLevel.medium;
    return ScoreLevel.low;
  }

  /// Ismdagi birinchi harf (avatar uchun)
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        level,
        averageScore,
        lastActiveAt,
        skillScores,
      ];

  @override
  String toString() =>
      'StudentSummary(id: $userId, name: $fullName, score: $averageScore)';
}

/// Ball darajasi
enum ScoreLevel {
  /// 80+ ball — yaxshi
  good,

  /// 50-79 ball — o'rta
  medium,

  /// 50 dan past — yaxshilash kerak
  low,
}
