// lib/features/student/progress/presentation/widgets/progress_chart.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/features/student/progress/domain/entities/progress.dart';

class ProgressChart extends StatelessWidget {
  final SkillScores skillScores;
  const ProgressChart({super.key, required this.skillScores});

  @override
  Widget build(BuildContext context) {
    final skills = {
      'Quiz': skillScores.quiz,
      'Flashcard': skillScores.flashcard,
      'Listening': skillScores.listening,
      'Speaking': skillScores.speaking,
      'Artikel': skillScores.artikel,
    };
    return Column(
      children: skills.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(e.key, style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.value.clamp(0, 1),
                    minHeight: 10,
                    
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(e.value * 100).round()}%',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
