// lib/features/student/progress/domain/entities/progress.dart
import 'package:equatable/equatable.dart';

class DailyActivity extends Equatable {
  final String date;
  final int xpEarned;
  final int minutesStudied;
  final int quizzesCompleted;
  final bool streakKept;

  const DailyActivity({
    required this.date,
    this.xpEarned = 0,
    this.minutesStudied = 0,
    this.quizzesCompleted = 0,
    this.streakKept = false,
  });

  bool get wasActive => xpEarned > 0 || minutesStudied > 0;
  @override
  List<Object?> get props => [date];
}

class SkillScores extends Equatable {
  final double quiz;
  final double flashcard;
  final double listening;
  final double speaking;
  final double artikel;

  const SkillScores({
    this.quiz = 0,
    this.flashcard = 0,
    this.listening = 0,
    this.speaking = 0,
    this.artikel = 0,
  });

  double get average => (quiz + flashcard + listening + speaking + artikel) / 5;
  @override
  List<Object?> get props => [quiz, flashcard, listening, speaking, artikel];
}

class UserProgress extends Equatable {
  final String userId;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int totalQuizzes;
  final double averageQuizScore;
  final SkillScores skillScores;
  final List<DailyActivity> recentActivity;
  final List<String> weakAreas;
  final DateTime updatedAt;

  const UserProgress({
    required this.userId,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalQuizzes = 0,
    this.averageQuizScore = 0.0,
    this.skillScores = const SkillScores(),
    this.recentActivity = const [],
    this.weakAreas = const [],
    required this.updatedAt,
  });

  String get currentLevel {
    if (totalXp >= 5000) return 'B2';
    if (totalXp >= 3000) return 'B1';
    if (totalXp >= 1500) return 'A2';
    return 'A1';
  }

  int get xpToNextLevel {
    if (totalXp >= 5000) return 0;
    if (totalXp >= 3000) return 5000 - totalXp;
    if (totalXp >= 1500) return 3000 - totalXp;
    return 1500 - totalXp;
  }

  @override
  List<Object?> get props => [userId, totalXp];
}
