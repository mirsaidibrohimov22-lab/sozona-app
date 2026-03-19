// lib/features/student/home/domain/entities/daily_plan.dart
import 'package:equatable/equatable.dart';

class DailyPlan extends Equatable {
  final String userId;
  final DateTime date;
  final List<DailyTask> tasks;
  final int totalXpToday;
  final int goalMinutes;
  final int completedMinutes;

  const DailyPlan({
    required this.userId,
    required this.date,
    required this.tasks,
    this.totalXpToday = 0,
    this.goalMinutes = 20,
    this.completedMinutes = 0,
  });

  double get completionRate => tasks.isEmpty
      ? 0
      : tasks.where((t) => t.isCompleted).length / tasks.length;

  @override
  List<Object?> get props => [userId, date];
}

class DailyTask extends Equatable {
  final String id;
  final String
      type; // 'quiz' | 'flashcard' | 'listening' | 'speaking' | 'artikel'
  final String title;
  final String? contentId;
  final bool isCompleted;
  final int xpReward;
  final int durationMinutes;

  const DailyTask({
    required this.id,
    required this.type,
    required this.title,
    this.contentId,
    this.isCompleted = false,
    this.xpReward = 10,
    this.durationMinutes = 5,
  });

  @override
  List<Object?> get props => [id];
}
