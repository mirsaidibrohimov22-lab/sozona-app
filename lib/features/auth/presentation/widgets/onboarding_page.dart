// lib/features/onboarding/presentation/widgets/onboarding_page.dart
// So'zona — Bitta onboarding sahifasi widgeti
// Ikonka + sarlavha + tavsif

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Onboarding sahifa ma'lumotlari
class OnboardingPageData {
  /// Sahifa ikonkasi
  final IconData icon;

  /// Sarlavha
  final String title;

  /// Tavsif matni
  final String description;

  /// Rang (ikonka foni)
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
  /// Sahifa ma'lumotlari
  final OnboardingPageData data;

  const OnboardingPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ikonka doirasi
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 64,
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
          ),
        ],
      ),
    );
  }
}
