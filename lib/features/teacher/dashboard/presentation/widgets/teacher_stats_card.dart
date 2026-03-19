// lib/features/teacher/dashboard/presentation/widgets/teacher_stats_card.dart
// So'zona — O'qituvchi kontent statistikasi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/animated_counter.dart';
import 'package:my_first_app/core/widgets/app_card.dart';

/// O'qituvchi kontent statistikasi kartochkasi
class TeacherStatsCard extends StatelessWidget {
  final int totalContent;
  final int publishedContent;

  const TeacherStatsCard({
    super.key,
    required this.totalContent,
    required this.publishedContent,
  });

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
              const Text('📄', style: TextStyle(fontSize: 28)),
              const SizedBox(width: AppSizes.spacingSm),
              AnimatedCounter(
                value: totalContent,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXs),
          const Text(
            'Kontent',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            totalContent == 0
                ? 'Hali kontent yo\'q'
                : '$publishedContent ta nashr qilingan',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
