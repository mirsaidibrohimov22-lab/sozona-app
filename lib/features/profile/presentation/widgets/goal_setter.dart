// QO'YISH: lib/features/profile/presentation/widgets/goal_setter.dart
// So'zona — Kunlik maqsad daqiqa tanlash

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class GoalSetter extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onChanged;

  const GoalSetter({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
  });

  static const List<int> options = [10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((min) {
        final isSelected = selectedMinutes == min;
        return GestureDetector(
          onTap: () => onChanged(min),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            child: Text(
              '$min min',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
