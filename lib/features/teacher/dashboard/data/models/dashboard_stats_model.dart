// lib/features/teacher/dashboard/data/models/dashboard_stats_model.dart
import 'package:my_first_app/features/teacher/dashboard/domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.teacherId,
    super.totalClasses,
    super.totalStudents,
    super.contentPublished,
    super.activeStudentsToday,
    super.avgClassScore,
    super.recentActivities,
    required super.updatedAt,
  });

  factory DashboardStatsModel.fromData(
    String teacherId, {
    required int totalClasses,
    required int totalStudents,
    required int contentPublished,
    required int activeToday,
    required double avgScore,
    required List<String> activities,
  }) =>
      DashboardStatsModel(
        teacherId: teacherId,
        totalClasses: totalClasses,
        totalStudents: totalStudents,
        contentPublished: contentPublished,
        activeStudentsToday: activeToday,
        avgClassScore: avgScore,
        recentActivities: activities,
        updatedAt: DateTime.now(),
      );
}
