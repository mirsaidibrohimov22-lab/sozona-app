// lib/core/widgets/app_dialog.dart
// So'zona — Dialog yordamchi funksiyalar
// Tasdiqlash, ma'lumot, xavf dialoglari

import 'package:flutter/material.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Dialog ko'rsatish uchun yordamchi klass
class AppDialog {
  /// Tasdiqlash dialogi
  /// Qaytaradi: true (tasdiqladi) yoki false (bekor qildi)
  static Future<bool> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ha',
    String cancelLabel = 'Bekor qilish',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Ma'lumot dialogi (faqat "OK" tugmasi)
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Tushundim',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  /// Chiqish tasdiqlash dialogi
  static Future<bool> showExitConfirm(BuildContext context) {
    return showConfirm(
      context,
      title: 'Chiqishni tasdiqlang',
      message: 'Haqiqatan ham tizimdan chiqmoqchimisiz?',
      confirmLabel: 'Chiqish',
      cancelLabel: 'Qolish',
      isDanger: true,
    );
  }

  /// O'chirish tasdiqlash dialogi
  static Future<bool> showDeleteConfirm(
    BuildContext context, {
    String? itemName,
  }) {
    return showConfirm(
      context,
      title: 'O\'chirishni tasdiqlang',
      message: itemName != null
          ? '"$itemName" ni o\'chirmoqchimisiz? Bu amalni qaytarib bo\'lmaydi.'
          : 'Bu elementni o\'chirmoqchimisiz? Bu amalni qaytarib bo\'lmaydi.',
      confirmLabel: 'O\'chirish',
      cancelLabel: 'Bekor qilish',
      isDanger: true,
    );
  }
}
