// lib/features/student/ai_tutor/presentation/widgets/recommendation_card.dart
// Tavsiya etilgan dars kartochkasi — contentId bilan bog'langan

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/student/ai_tutor/presentation/providers/ai_tutor_provider.dart';

class RecommendationCard extends StatelessWidget {
  final TutorRecommendation rec;
  final VoidCallback onTap;

  const RecommendationCard({
    super.key,
    required this.rec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config(rec.reason);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: cfg.borderColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingMd),
          child: Row(
            children: [
              // Ikonka
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cfg.iconBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(cfg.icon, color: cfg.iconColor, size: 22),
              ),
              const SizedBox(width: AppSizes.spacingMd),

              // Matn
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rec.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Daraja badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rec.level,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Sabab
                    Row(
                      children: [
                        Icon(cfg.reasonIcon, size: 12, color: cfg.reasonColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            rec.reasonUz,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: cfg.reasonColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Mavzu chip
                    if (rec.topic.isNotEmpty)
                      Text(
                        rec.topic,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),

              // O'q
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CardConfig _config(String reason) {
    switch (reason) {
      case 'spaced_repetition':
        return _CardConfig(
          icon: Icons.replay_rounded,
          iconColor: AppColors.accent,
          iconBg: AppColors.accent.withOpacity(0.12),
          borderColor: AppColors.accent,
          reasonIcon: Icons.access_time_rounded,
          reasonColor: AppColors.accent,
        );
      case 'weakness_targeted':
        return _CardConfig(
          icon: Icons.fitness_center_rounded,
          iconColor: AppColors.secondary,
          iconBg: AppColors.secondaryContainer,
          borderColor: AppColors.secondary,
          reasonIcon: Icons.trending_up_rounded,
          reasonColor: AppColors.secondaryDark,
        );
      default:
        return _CardConfig(
          icon: Icons.menu_book_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primaryContainer,
          borderColor: AppColors.primary,
          reasonIcon: Icons.auto_awesome_rounded,
          reasonColor: AppColors.primaryDark,
        );
    }
  }
}

class _CardConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color borderColor;
  final IconData reasonIcon;
  final Color reasonColor;

  const _CardConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.borderColor,
    required this.reasonIcon,
    required this.reasonColor,
  });
}
