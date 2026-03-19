// lib/core/widgets/app_badge.dart
// So'zona — Badge widgeti
// Daraja, streak, XP, holat badge'lari

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Badge turi
enum BadgeType {
  /// CEFR daraja badge (A1, B2 va h.k.)
  level,

  /// Streak badge (🔥 5 kun)
  streak,

  /// XP badge (⭐ 150)
  xp,

  /// Holat badge (Yangi, Tugallangan va h.k.)
  status,
}

/// Badge widgeti — kichik rang belgi
class AppBadge extends StatelessWidget {
  /// Badge matni
  final String label;

  /// Badge turi
  final BadgeType type;

  /// Maxsus rang (ixtiyoriy)
  final Color? color;

  /// Chap ikonka (ixtiyoriy)
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.type = BadgeType.status,
    this.color,
    this.icon,
  });

  /// CEFR daraja badge
  factory AppBadge.level(String level) {
    return AppBadge(
      label: level.toUpperCase(),
      type: BadgeType.level,
      icon: Icons.school_outlined,
    );
  }

  /// Streak badge
  factory AppBadge.streak(int days) {
    return AppBadge(
      label: '$days kun',
      type: BadgeType.streak,
      icon: Icons.local_fire_department,
    );
  }

  /// XP badge
  factory AppBadge.xp(int points) {
    return AppBadge(
      label: '$points XP',
      type: BadgeType.xp,
      icon: Icons.star,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingSm,
        vertical: AppSizes.spacingXs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Tur bo'yicha rang
  Color _getColor() {
    switch (type) {
      case BadgeType.level:
        return AppColors.primary;
      case BadgeType.streak:
        return AppColors.streak;
      case BadgeType.xp:
        return AppColors.xp;
      case BadgeType.status:
        return AppColors.info;
    }
  }
}
