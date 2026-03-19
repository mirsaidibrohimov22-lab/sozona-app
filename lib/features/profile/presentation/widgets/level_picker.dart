// QO'YISH: lib/features/profile/presentation/widgets/level_picker.dart
// So'zona — Daraja tanlash widget

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/widgets/level_badge.dart';

class LevelPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const LevelPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: levels.map((level) {
        final isSelected = selected == level;
        return GestureDetector(
          onTap: () => onChanged(level),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: LevelBadge(level: level, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }
}
