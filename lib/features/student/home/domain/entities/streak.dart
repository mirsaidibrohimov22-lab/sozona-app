// lib/features/student/home/domain/entities/streak.dart
import 'package:equatable/equatable.dart';

class Streak extends Equatable {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final bool isActiveToday;
  final List<bool> last7Days; // true = faol bo'lgan kun

  const Streak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.isActiveToday = false,
    this.last7Days = const [],
  });

  bool get isAtRisk {
    if (lastActiveDate == null) return false;
    final diff = DateTime.now().difference(lastActiveDate!).inHours;
    return diff > 20 && !isActiveToday;
  }

  @override
  List<Object?> get props => [userId, currentStreak];
}
