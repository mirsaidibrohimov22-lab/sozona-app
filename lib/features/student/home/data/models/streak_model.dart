// lib/features/student/home/data/models/streak_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/features/student/home/domain/entities/streak.dart';

class StreakModel extends Streak {
  const StreakModel({
    required super.userId,
    super.currentStreak,
    super.longestStreak,
    super.lastActiveDate,
    super.isActiveToday,
    super.last7Days,
  });

  factory StreakModel.fromFirestore(Map<String, dynamic> data, String userId) {
    final today = DateTime.now();
    final lastDate = (data['lastActiveDate'] as Timestamp?)?.toDate();
    final isToday = lastDate != null &&
        lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day;
    return StreakModel(
      userId: userId,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (data['longestStreak'] as num?)?.toInt() ?? 0,
      lastActiveDate: lastDate,
      isActiveToday: isToday,
      last7Days: List<bool>.from(data['last7Days'] ?? List.filled(7, false)),
    );
  }
}
