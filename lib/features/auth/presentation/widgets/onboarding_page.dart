// lib/features/auth/presentation/widgets/onboarding_page.dart
// So'zona — Bitta onboarding sahifasi widgeti
// ✅ RESPONSIVE FIX:
//   - height: 140 (fixed) → (screenH * 0.16).clamp(100, 150) (adaptive)
//   - description text: maxLines + ellipsis qo'shildi

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Onboarding sahifa ma'lumotlari
class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

/// Bitta onboarding sahifasi
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // ✅ Adaptive: iPhone SE (667px) → 107px, S24 (900px) → 144px
    final iconCircleSize = (screenHeight * 0.16).clamp(100.0, 150.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ikonka doirasi — adaptive o'lcham
          Container(
            width: iconCircleSize,
            height: iconCircleSize,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: iconCircleSize * 0.46,
              color: data.color,
            ),
          ),

          const SizedBox(height: AppSizes.spacingXl),

          // Sarlavha
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Tavsif
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
            // ✅ maxLines qo'shildi — kichik ekranda overflow bo'lmaydi
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
