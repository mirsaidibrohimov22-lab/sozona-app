// lib/features/teacher/analytics/presentation/widgets/ai_advice_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/teacher/analytics/presentation/providers/teacher_analytics_provider.dart';

class AiAdviceCard extends ConsumerWidget {
  final String classId;
  const AiAdviceCard({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adviceAsync = ref.watch(aiAdviceProvider(classId));
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🤖', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  'AI maslahati',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            adviceAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const Text('Maslahot yuklanmadi'),
              data: Text.new,
            ),
          ],
        ),
      ),
    );
  }
}
