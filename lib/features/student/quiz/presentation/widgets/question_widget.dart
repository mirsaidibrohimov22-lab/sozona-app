import 'package:flutter/material.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/presentation/widgets/mcq_options.dart';
import 'package:my_first_app/features/student/quiz/presentation/widgets/true_false_buttons.dart';
import 'package:my_first_app/features/student/quiz/presentation/widgets/fill_blank_input.dart';

/// Question Widget — savolni ko'rsatish
class QuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final int? selectedIndex;
  final Function(int) onAnswerSelected;

  const QuestionWidget({
    super.key,
    required this.question,
    this.selectedIndex,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Chip(
              label: Text(question.typeLabel),
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
            ),
            const Spacer(),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < question.difficulty ? Icons.star : Icons.star_border,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildAnswerComponent(),
      ],
    );
  }

  Widget _buildAnswerComponent() {
    switch (question.type) {
      case QuestionType.mcq:
      case QuestionType.artikel:
        return McqOptions(
          options: question.options,
          selectedIndex: selectedIndex,
          onSelected: onAnswerSelected,
        );
      case QuestionType.trueFalse:
        return TrueFalseButtons(
          selectedIndex: selectedIndex,
          onSelected: onAnswerSelected,
        );
      case QuestionType.fillBlank:
        return FillBlankInput(
          questionText: question.question,
          controller: TextEditingController(),
          isAnswered: false,
        );
    }
  }
}
