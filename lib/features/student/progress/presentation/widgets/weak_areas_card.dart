// lib/features/student/progress/presentation/widgets/weak_areas_card.dart
import 'package:flutter/material.dart';

class WeakAreasCard extends StatelessWidget {
  final List<String> weakAreas;
  const WeakAreasCard({super.key, required this.weakAreas});

  static const _labels = {
    'quiz': 'Quiz',
    'flashcard': 'Flashcard',
    'listening': 'Listening',
    'speaking': 'Speaking',
    'artikel': 'Artikel (der/die/das)',
  };
  static const _icons = {
    'quiz': '📝',
    'flashcard': '🗂️',
    'listening': '🎧',
    'speaking': '🎙️',
    'artikel': '🇩🇪',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: weakAreas
              .map(
                (area) => ListTile(
                  leading: Text(
                    _icons[area] ?? '⚠️',
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(_labels[area] ?? area),
                  subtitle: const Text('Mashq tavsiya etiladi'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  dense: true,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
