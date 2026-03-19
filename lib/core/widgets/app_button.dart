// lib/core/widgets/app_button.dart
// So'zona — Asosiy tugma widgeti
// Primary, Secondary, Outlined variantlar

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Tugma turi
enum AppButtonType {
  /// Asosiy — to'ldirilgan rang
  primary,

  /// Ikkinchi darajali — ochiq rang
  secondary,

  /// Chegarali — faqat border
  outlined,

  /// Xavfli — qizil (o'chirish va h.k.)
  danger,
}

/// Tugma o'lchami
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Qayta ishlatiluvchi tugma widgeti
class AppButton extends StatelessWidget {
  /// Tugma matni
  final String label;

  /// Bosilganda
  final VoidCallback? onPressed;

  /// Tugma turi
  final AppButtonType type;

  /// Tugma o'lchami
  final AppButtonSize size;

  /// Chap ikonka (ixtiyoriy)
  final IconData? icon;

  /// Yuklanish holati
  final bool isLoading;

  /// To'liq kenglik
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final buttonChild = _buildChild();

    Widget button;

    switch (type) {
      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
      case AppButtonType.danger:
      case AppButtonType.primary:
      case AppButtonType.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: buttonChild,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  /// Tugma ichidagi widget
  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        height: _getLoaderSize(),
        width: _getLoaderSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == AppButtonType.outlined ? AppColors.primary : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppSizes.spacingSm),
          Text(label, style: TextStyle(fontSize: _getFontSize())),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Tugma stili
  ButtonStyle _getButtonStyle() {
    final padding = _getPadding();
    final radius = BorderRadius.circular(AppSizes.radiusMd);

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        );
      case AppButtonType.secondary:
        return ElevatedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        );
      case AppButtonType.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: const BorderSide(color: AppColors.primary),
        );
      case AppButtonType.danger:
        return ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        );
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 15;
      case AppButtonSize.large:
        return 17;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  double _getLoaderSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }
}
