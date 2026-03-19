// QO'YISH: lib/core/widgets/app_snackbar.dart
// So'zona — Global SnackBar helper

import 'package:flutter/material.dart';

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    IconData icon = Icons.info_outline;

    if (isError) {
      icon = Icons.error_outline;
    } else if (isSuccess) {
      icon = Icons.check_circle_outline;
    }

    final bgColor = isError
        ? Colors.red.shade700
        : isSuccess
            ? Colors.green.shade700
            : Colors.grey.shade800;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: action,
        ),
      );
  }

  static void success(BuildContext context, String message) {
    show(context, message, isSuccess: true);
  }

  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  /// Alias for error() — used in some screens
  static void showError(BuildContext context, String message) {
    error(context, message);
  }
}
