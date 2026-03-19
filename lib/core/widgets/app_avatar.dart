// lib/core/widgets/app_avatar.dart
// So'zona — Foydalanuvchi avatar widgeti
// Rasm bor bo'lsa ko'rsatadi, yo'q bo'lsa ism bosh harfi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';

/// Avatar o'lchami
enum AvatarSize {
  small(32),
  medium(48),
  large(64),
  extraLarge(96);

  final double size;
  const AvatarSize(this.size);
}

/// Foydalanuvchi avatar widgeti
class AppAvatar extends StatelessWidget {
  /// Rasm URL (ixtiyoriy)
  final String? imageUrl;

  /// Foydalanuvchi ismi (bosh harf uchun)
  final String name;

  /// Avatar o'lchami
  final AvatarSize size;

  /// Chegara bormi
  final bool showBorder;

  /// Online indikator
  final bool showOnlineIndicator;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AvatarSize.medium,
    this.showBorder = false,
    this.showOnlineIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar
        Container(
          width: size.size,
          height: size.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: showBorder
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    width: size.size,
                    height: size.size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallback(),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return _buildFallback();
                    },
                  )
                : _buildFallback(),
          ),
        ),

        // Online indikator
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size.size * 0.28,
              height: size.size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// Rasm yo'q bo'lganda bosh harf ko'rsatish
  Widget _buildFallback() {
    final initials = _getInitials(name);
    final bgColor = _getColorFromName(name);

    return Container(
      width: size.size,
      height: size.size,
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Ismdan bosh harflarni olish
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Ism asosida rang tanlash (har doim bir xil)
  Color _getColorFromName(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.info,
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}
