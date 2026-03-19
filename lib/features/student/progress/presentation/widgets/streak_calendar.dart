// lib/features/student/progress/presentation/widgets/streak_calendar.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/features/student/progress/domain/entities/progress.dart';

class StreakCalendar extends StatelessWidget {
  final List<DailyActivity> activities;
  const StreakCalendar({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final isActive = i < activities.length && activities[i].wasActive;
            return Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.orange : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isActive ? '🔥' : '·',
                      style: TextStyle(
                        fontSize: isActive ? 16 : 20,
                        color: isActive ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(days[i], style: const TextStyle(fontSize: 10)),
              ],
            );
          }),
        ),
      ),
    );
  }
}
