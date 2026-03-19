// QO'YISH: lib/core/widgets/level_badge.dart
// So'zona — Daraja belgisi (A1, A2, B1...)

import 'package:flutter/material.dart';

class LevelBadge extends StatelessWidget {
  final String level;
  final double fontSize;

  const LevelBadge({super.key, required this.level, this.fontSize = 11});

  Color get _color {
    switch (level.toUpperCase()) {
      case 'A1':
        return Colors.green.shade400;
      case 'A2':
        return Colors.lightGreen.shade600;
      case 'B1':
        return Colors.blue.shade400;
      case 'B2':
        return Colors.indigo.shade400;
      case 'C1':
        return Colors.purple.shade400;
      case 'C2':
        return Colors.deepPurple.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color, width: 1.2),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}
