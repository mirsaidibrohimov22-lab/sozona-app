// lib/features/student/home/presentation/widgets/recommended_lesson_card.dart
// So'zona — Tavsiya etilgan dars kartochkasi
// AI tomonidan tavsiya qilingan keyingi mashq

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Tavsiya etilgan dars kartochkasi
class RecommendedLessonCard extends StatelessWidget {
  const RecommendedLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Hozircha statik tavsiya — keyinchalik AI orqali dinamik bo'ladi
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(RoutePaths.flashcards),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingLg),
            child: Row(
              children: [
                // Chap qism — matn
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI tavsiyasi belgisi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingSm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI tavsiyasi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingSm),

                      // Dars nomi
                      const Text(
                        'So\'z boyligini oshiring',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Tavsif
                      Text(
                        'Yangi so\'zlar bilan flashcard mashq qiling',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingMd),

                      // Boshlash tugmasi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingMd,
                          vertical: AppSizes.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Boshlash',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // O'ng qism — rasm/emoji
                const SizedBox(width: AppSizes.spacingMd),
                const Text(
                  '📚',
                  style: TextStyle(fontSize: 48),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
