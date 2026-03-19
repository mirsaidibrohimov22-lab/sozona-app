// lib/features/student/home/presentation/widgets/mini_progress_widget.dart
import 'package:flutter/material.dart';

class MiniProgressWidget extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final String label;
  final Color? color;

  const MiniProgressWidget({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clr = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: clr,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: clr.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(clr),
          ),
        ),
      ],
    );
  }
}
