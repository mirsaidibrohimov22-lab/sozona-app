import 'package:flutter/material.dart';

class MasteryIndicator extends StatelessWidget {
  final double mastery; // 0.0 - 1.0
  final double size;

  const MasteryIndicator({super.key, required this.mastery, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = mastery >= 0.8
        ? Colors.green
        : mastery >= 0.5
            ? Colors.orange
            : Colors.red;
    return SizedBox(
      width: size, height: size,
      child: CircularProgressIndicator(
        value: mastery,
        backgroundColor: color.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: 4,
      ),
    );
  }
}
