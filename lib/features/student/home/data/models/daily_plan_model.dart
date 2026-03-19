// lib/features/student/home/data/models/daily_plan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/student/home/domain/entities/daily_plan.dart';

class DailyPlanModel extends DailyPlan {
  const DailyPlanModel({
    required super.userId,
    required super.date,
    required super.tasks,
    super.totalXpToday,
    super.goalMinutes,
    super.completedMinutes,
  });

  factory DailyPlanModel.fromFirestore(
    Map<String, dynamic> data,
    String userId,
  ) {
    final rawTasks = data['tasks'] as List<dynamic>? ?? [];
    return DailyPlanModel(
      userId: userId,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tasks: rawTasks.map((t) {
        final m = t as Map<String, dynamic>;
        return DailyTask(
          id: m['id'] as String? ?? '',
          type: m['type'] as String? ?? 'quiz',
          title: m['title'] as String? ?? '',
          contentId: m['contentId'] as String?,
          isCompleted: m['isCompleted'] as bool? ?? false,
          xpReward: (m['xpReward'] as num?)?.toInt() ?? 10,
          durationMinutes: (m['durationMinutes'] as num?)?.toInt() ?? 5,
        );
      }).toList(),
      totalXpToday: (data['totalXpToday'] as num?)?.toInt() ?? 0,
      goalMinutes: (data['goalMinutes'] as num?)?.toInt() ?? 20,
      completedMinutes: (data['completedMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
