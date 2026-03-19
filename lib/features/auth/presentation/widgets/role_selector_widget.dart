// lib/features/auth/presentation/widgets/role_selector_widget.dart
// So'zona — Rol tanlash widgeti
// Student yoki Teacher — katta kartochkalar bilan

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';

/// Rol tanlash widgeti — Student va Teacher
class RoleSelectorWidget extends StatelessWidget {
  /// Hozirgi tanlangan rol
  final UserRole selectedRole;

  /// Rol tanlanganda callback
  final void Function(UserRole role) onRoleSelected;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // O'quvchi kartochkasi
        _RoleCard(
          icon: Icons.school_outlined,
          title: 'O\'quvchi',
          subtitle: 'Til o\'rganmoqchiman',
          description: 'Flashcard, quiz, listening, speaking va AI mashqlari',
          isSelected: selectedRole == UserRole.student,
          onTap: () => onRoleSelected(UserRole.student),
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // O'qituvchi kartochkasi
        _RoleCard(
          icon: Icons.workspace_premium_outlined,
          title: 'O\'qituvchi',
          subtitle: 'O\'quvchilarga yordam bermoqchiman',
          description: 'Sinf yaratish, AI bilan kontent yaratish, natijalar',
          isSelected: selectedRole == UserRole.teacher,
          onTap: () => onRoleSelected(UserRole.teacher),
        ),
      ],
    );
  }
}

/// Rol kartochkasi — ichki widget
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.bgTertiary,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Ikonka doirasi
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: AppSizes.spacingMd),

            // Matn
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Tanlangan belgi
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bgTertiary,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
