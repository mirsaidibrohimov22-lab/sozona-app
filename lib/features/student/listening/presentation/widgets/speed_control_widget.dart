// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Speed Control Widget
// QO'YISH: lib/features/student/listening/presentation/widgets/speed_control_widget.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';

/// Speed Control Widget — audio tezligini boshqarish
class SpeedControlWidget extends StatelessWidget {
  final double currentSpeed;
  final Function(double) onSpeedChanged;

  const SpeedControlWidget({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currentSpeed}x',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
      onSelected: onSpeedChanged,
      itemBuilder: (context) => [
        _buildSpeedItem(0.5, 'Sekin'),
        _buildSpeedItem(0.75, 'Biroz sekin'),
        _buildSpeedItem(1.0, 'Oddiy'),
        _buildSpeedItem(1.25, 'Biroz tez'),
        _buildSpeedItem(1.5, 'Tez'),
        _buildSpeedItem(2.0, 'Juda tez'),
      ],
    );
  }

  PopupMenuItem<double> _buildSpeedItem(double speed, String label) {
    final isSelected = speed == currentSpeed;

    return PopupMenuItem(
      value: speed,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: isSelected
                ? const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppColors.primary,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            '${speed}x',
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
