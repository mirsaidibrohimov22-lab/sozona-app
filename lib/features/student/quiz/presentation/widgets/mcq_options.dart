// lib/features/student/quiz/presentation/widgets/mcq_options.dart
import 'package:flutter/material.dart';

class McqOptions extends StatelessWidget {
  final List<String> options;
  final int? selectedIndex;
  final int? correctIndex;
  final bool isAnswered;
  final ValueChanged<int>? onSelected;

  const McqOptions({
    super.key,
    required this.options,
    this.selectedIndex,
    this.correctIndex,
    this.isAnswered = false,
    this.onSelected,
  });

  Color _getColor(int index) {
    if (!isAnswered) return Colors.transparent;
    if (index == correctIndex) return Colors.green.shade100;
    if (index == selectedIndex && index != correctIndex) {
      return Colors.red.shade100;
    }
    return Colors.transparent;
  }

  IconData? _getIcon(int index) {
    if (!isAnswered) return null;
    if (index == correctIndex) return Icons.check_circle;
    if (index == selectedIndex && index != correctIndex) return Icons.cancel;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (i) {
        final icon = _getIcon(i);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: isAnswered ? null : () => onSelected?.call(i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _getColor(i),
                border: Border.all(
                  color: selectedIndex == i && !isAnswered
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  width: selectedIndex == i ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(options[i])),
                  if (icon != null)
                    Icon(
                      icon,
                      color: icon == Icons.check_circle
                          ? Colors.green
                          : Colors.red,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
