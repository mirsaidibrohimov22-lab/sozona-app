// lib/features/teacher/dashboard/presentation/widgets/quick_create_button.dart
// So'zona — Tezkor yaratish tugmalari
// Quiz, Flashcard, Listening yaratish uchun tezkor tugmalar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Tezkor yaratish tugmalari
class QuickCreateButton extends StatelessWidget {
  const QuickCreateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CreateItem(
            icon: Icons.quiz_outlined,
            label: 'Quiz',
            color: AppColors.primary,
            onTap: () => context.push(RoutePaths.contentGenerator),
          ),
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: _CreateItem(
            icon: Icons.style_outlined,
            label: 'Kartochka',
            color: AppColors.secondary,
            onTap: () => context.push(RoutePaths.contentGenerator),
          ),
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: _CreateItem(
            icon: Icons.headphones_outlined,
            label: 'Tinglash',
            color: AppColors.accent,
            onTap: () => context.push(RoutePaths.contentGenerator),
          ),
        ),
      ],
    );
  }
}

/// Bitta yaratish tugmasi
class _CreateItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CreateItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spacingMd,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSizes.spacingXs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
