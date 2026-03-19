// lib/features/auth/presentation/widgets/auth_text_field.dart
// So'zona — Auth ekranlar uchun maxsus input widget
// Barcha auth formalarda qayta ishlatiladi

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Auth ekranlar uchun stillantirilgan text field
class AuthTextField extends StatelessWidget {
  /// Controller
  final TextEditingController controller;

  /// Ustidagi yorliq
  final String label;

  /// Placeholder matni
  final String? hint;

  /// Validatsiya funksiyasi
  final String? Function(String?)? validator;

  /// Klaviatura turi
  final TextInputType? keyboardType;

  /// Parol rejimi
  final bool obscureText;

  /// Chap ikonka
  final IconData? prefixIcon;

  /// O'ng widget (ko'z ikonka va h.k.)
  final Widget? suffixIcon;

  /// Matn bosh harfi
  final TextCapitalization textCapitalization;

  /// Kiritish tugaganda
  final void Function(String)? onFieldSubmitted;

  /// Input action turi
  final TextInputAction? textInputAction;

  /// Avtomatik fokus
  final bool autofocus;

  /// Maksimal uzunlik
  final int? maxLength;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofocus = false,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yorliq
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: AppSizes.spacingXs),

        // Text field
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          onFieldSubmitted: onFieldSubmitted,
          textInputAction: textInputAction,
          autofocus: autofocus,
          maxLength: maxLength,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: 22)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.bgPrimary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingMd,
              vertical: AppSizes.spacingMd,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.bgTertiary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.bgTertiary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
            counterText: '', // Belgini yashirish
          ),
        ),
      ],
    );
  }
}
