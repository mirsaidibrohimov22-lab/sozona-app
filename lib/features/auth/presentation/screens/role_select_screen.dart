// lib/features/auth/presentation/screens/role_select_screen.dart
// So'zona — Rol tanlash ekrani (Student yoki Teacher)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';

/// Ro'yxatdan o'tgandan keyin rolni tanlash ekrani
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Siz kimsiz?',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                'Rolni tanlang — keyin ham o\'zgartirish mumkin',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _RoleCard(
                icon: Icons.school,
                title: 'O\'quvchi',
                subtitle: 'Til o\'rganmoqchiman',
                color: AppColors.primary,
                onTap: () => _selectRole(context, ref, UserRole.student),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.person,
                title: 'O\'qituvchi',
                subtitle: 'O\'quvchilarga dars beraman',
                color: AppColors.secondary,
                onTap: () => _selectRole(context, ref, UserRole.teacher),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, WidgetRef ref, UserRole role) {
    context.go(RoutePaths.setupProfile, extra: {'role': role});
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
