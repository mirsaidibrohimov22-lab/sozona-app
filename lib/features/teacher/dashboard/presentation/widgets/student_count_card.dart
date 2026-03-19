// lib/features/teacher/dashboard/presentation/widgets/student_count_card.dart
// So'zona — O'quvchilar soni kartochkasi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_card.dart';

/// O'quvchilar soni kartochkasi
class StudentCountCard extends StatelessWidget {
  final int count;

  const StudentCountCard({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: AppColors.bgTertiary,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👨‍🎓', style: TextStyle(fontSize: 28)),
              const SizedBox(width: AppSizes.spacingSm),
              AnimatedCounter(
                value: count,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXs),
          const Text(
            'O\'quvchilar',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count == 0 ? 'Hali o\'quvchi yo\'q' : 'Barcha sinflarda',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
