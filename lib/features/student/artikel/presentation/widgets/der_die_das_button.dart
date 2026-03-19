// lib/features/student/artikel/presentation/widgets/der_die_das_button.dart
import 'package:flutter/material.dart';

class DerDieDasButton extends StatelessWidget {
  final String artikel;
  final bool isSelected;
  final bool? isCorrect; // null = not answered yet
  final VoidCallback onTap;

  const DerDieDasButton({
    super.key,
    required this.artikel,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  Color get _color {
    if (isCorrect == null) {
      return isSelected ? Colors.blue : Colors.grey.shade200;
    }
    if (isCorrect! && isSelected) return Colors.green;
    if (!isCorrect! && isSelected) return Colors.red;
    if (isCorrect! && !isSelected) return Colors.green.shade100;
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            artikel,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
