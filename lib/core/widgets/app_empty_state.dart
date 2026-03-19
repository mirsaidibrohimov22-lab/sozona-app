// lib/core/widgets/app_empty_state.dart
// So'zona — Bo'sh holat widgeti
// Ma'lumot yo'q bo'lganda ko'rsatiladi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Bo'sh holat widgeti
class AppEmptyWidget extends StatelessWidget {
  /// Xabar matni
  final String message;

  /// Sarlavha (ixtiyoriy)
  final String? title;

  /// Ikonka
  final IconData icon;

  /// Harakat tugmasi (ixtiyoriy)
  final String? actionLabel;

  /// Tugma bosilganda
  final VoidCallback? onAction;

  const AppEmptyWidget({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// Flashcard yo'q
  factory AppEmptyWidget.noFlashcards({VoidCallback? onAction}) {
    return AppEmptyWidget(
      title: 'Hali kartochkalar yo\'q',
      message:
          'Birinchi kartochka to\'plamingizni yarating yoki AI dan so\'rang',
      icon: Icons.style_outlined,
      actionLabel: 'Yaratish',
      onAction: onAction,
    );
  }

  /// Quiz yo'q
  factory AppEmptyWidget.noQuizzes({VoidCallback? onAction}) {
    return AppEmptyWidget(
      title: 'Hali quizlar yo\'q',
      message: 'AI yordamida darajangizga mos quiz yarating',
      icon: Icons.quiz_outlined,
      actionLabel: 'Quiz yaratish',
      onAction: onAction,
    );
  }

  /// Sinf yo'q (o'qituvchi uchun)
  factory AppEmptyWidget.noClasses({VoidCallback? onAction}) {
    return AppEmptyWidget(
      title: 'Hali sinflar yo\'q',
      message: 'Birinchi sinfingizni yarating va o\'quvchilarni taklif qiling',
      icon: Icons.class_outlined,
      actionLabel: 'Sinf yaratish',
      onAction: onAction,
    );
  }

  /// Bildirishnoma yo'q
  factory AppEmptyWidget.noNotifications() {
    return const AppEmptyWidget(
      title: 'Bildirishnomalar yo\'q',
      message: 'Hozircha yangi bildirishnoma yo\'q',
      icon: Icons.notifications_none,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikonka
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Sarlavha
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Xabar
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),

            // Harakat tugmasi
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.spacingXl),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingXl,
                    vertical: AppSizes.spacingMd,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
