// lib/features/student/quiz/presentation/widgets/true_false_buttons.dart
import 'package:flutter/material.dart';

class TrueFalseButtons extends StatelessWidget {
  final int? selectedIndex;
  final int? correctIndex;
  final bool isAnswered;
  final ValueChanged<int>? onSelected;

  const TrueFalseButtons({
    super.key,
    this.selectedIndex,
    this.correctIndex,
    this.isAnswered = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TFButton(
            label: 'To\'g\'ri ✅',
            index: 0,
            selectedIndex: selectedIndex,
            correctIndex: correctIndex,
            isAnswered: isAnswered,
            onTap: () => onSelected?.call(0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TFButton(
            label: 'Noto\'g\'ri ❌',
            index: 1,
            selectedIndex: selectedIndex,
            correctIndex: correctIndex,
            isAnswered: isAnswered,
            onTap: () => onSelected?.call(1),
          ),
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final int index;
  final int? selectedIndex;
  final int? correctIndex;
  final bool isAnswered;
  final VoidCallback onTap;

  const _TFButton({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color? bg = !isAnswered
        ? null
        : index == correctIndex
            ? Colors.green.shade100
            : index == selectedIndex
                ? Colors.red.shade100
                : null;
    final isSelected = selectedIndex == index;
    return ElevatedButton(
      onPressed: isAnswered ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        side: isSelected && !isAnswered
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
