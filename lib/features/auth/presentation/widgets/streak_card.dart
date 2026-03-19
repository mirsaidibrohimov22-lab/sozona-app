// lib/features/student/home/presentation/widgets/streak_card.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/features/student/home/domain/entities/streak.dart';

class StreakCard extends StatelessWidget {
  final Streak streak;
  const StreakCard({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: streak.isAtRisk
            ? LinearGradient(
                colors: [Colors.orange.shade400, Colors.red.shade400],
              )
            : const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C00)],
              ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${streak.currentStreak} kunlik streak',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  streak.isAtRisk
                      ? '⚠️ Bugun mashq qilmadingiz!'
                      : streak.isActiveToday
                          ? '✅ Bugun bajarildi'
                          : 'Davom eting!',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (streak.longestStreak > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${streak.longestStreak}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'eng uzun',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
