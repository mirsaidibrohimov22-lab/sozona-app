// lib/core/widgets/app_error_widget.dart
// ✅ FIX: SafeArea + SingleChildScrollView + ConstrainedBox qo'shildi
// Natija: "RenderFlex overflowed by 576 pixels" xatosi yo'qoladi

import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';

/// Xatolik widgeti — qayta urinish tugmasi bilan
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String? title;
  final bool compact;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.title,
    this.compact = false,
  });

  factory AppErrorWidget.network({VoidCallback? onRetry}) => AppErrorWidget(
        title: 'Internet aloqasi yo\'q',
        message:
            'Iltimos, internet ulanishingizni tekshiring va qayta urinib ko\'ring',
        icon: Icons.wifi_off_rounded,
        onRetry: onRetry,
      );

  factory AppErrorWidget.server({VoidCallback? onRetry}) => AppErrorWidget(
        title: 'Server xatoligi',
        message: 'Serverda muammo yuz berdi. Biroz kutib qayta urinib ko\'ring',
        icon: Icons.cloud_off_rounded,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFullSize(context);
  }

  // ✅ FIX: SafeArea + SingleChildScrollView + ConstrainedBox
  // Eski: Center > Column(mainAxisSize: min) — scroll yo'q, overflow bo'ldi
  Widget _buildFullSize(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingXl,
                vertical: AppSizes.spacingXl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: AppColors.error),
                  ),
                  const SizedBox(height: AppSizes.spacingLg),
                  if (title != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSizes.spacingSm),
                      child: Text(
                        title!,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                    // ✅ F FIX: uzun raw error matnini cheklash — overflow oldini oladi
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSizes.spacingXl),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Qayta urinish'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingXl,
                            vertical: AppSizes.spacingMd,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.error),
          const SizedBox(width: AppSizes.spacingSm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}
