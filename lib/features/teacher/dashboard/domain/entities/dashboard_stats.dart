// lib/features/teacher/dashboard/domain/entities/dashboard_stats.dart
import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final String teacherId;
  final int totalClasses;
  final int totalStudents;
  final int contentPublished;
  final int activeStudentsToday;
  final double avgClassScore;
  final List<String> recentActivities;
  final DateTime updatedAt;

  const DashboardStats({
    required this.teacherId,
    this.totalClasses = 0,
    this.totalStudents = 0,
    this.contentPublished = 0,
    this.activeStudentsToday = 0,
    this.avgClassScore = 0,
    this.recentActivities = const [],
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [teacherId];
}
