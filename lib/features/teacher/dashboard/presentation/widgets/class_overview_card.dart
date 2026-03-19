// lib/features/teacher/dashboard/presentation/widgets/class_overview_card.dart
// So'zona — Sinf ko'rish kartochkasi
// Bitta sinf haqida qisqacha ma'lumot

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/app_card.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/providers/teacher_dashboard_provider.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Sinf ko'rish kartochkasi
class ClassOverviewCard extends StatelessWidget {
  final ClassSummary classSummary;

  const ClassOverviewCard({super.key, required this.classSummary});

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      onTap: () => context.push(RoutePaths.classDetailPath(classSummary.id)),
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Row(
        children: [
          // Sinf ikonkasi
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.class_,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: AppSizes.spacingMd),

          // Ma'lumot
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classSummary.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${classSummary.studentCount} o\'quvchi',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // O'ng — oxirgi faollik
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                classSummary.lastActivity,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
