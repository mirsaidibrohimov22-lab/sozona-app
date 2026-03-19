// lib/features/student/quiz/presentation/widgets/fill_blank_input.dart
import 'package:flutter/material.dart';

class FillBlankInput extends StatelessWidget {
  final String questionText;
  final TextEditingController controller;
  final bool isAnswered;
  final bool isCorrect;

  const FillBlankInput({
    super.key,
    required this.questionText,
    required this.controller,
    this.isAnswered = false,
    this.isCorrect = false,
  });

  @override
  Widget build(BuildContext context) {
    final parts = questionText.split('___');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.length >= 2) ...[
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(parts[0], style: Theme.of(context).textTheme.bodyLarge),
              Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: controller,
                  enabled: !isAnswered,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: isAnswered,
                    fillColor: isAnswered
                        ? (isCorrect
                            ? Colors.green.shade100
                            : Colors.red.shade100)
                        : null,
                    border: const UnderlineInputBorder(),
                  ),
                ),
              ),
              if (parts.length > 1)
                Text(parts[1], style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ] else
          TextField(
            controller: controller,
            enabled: !isAnswered,
            decoration: const InputDecoration(
              hintText: 'Javobingizni kiriting',
              border: OutlineInputBorder(),
            ),
          ),
      ],
    );
  }
}
