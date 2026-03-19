// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Speaking Feedback Card
// QO'YISH: lib/features/student/speaking/presentation/widgets/speaking_feedback_card.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

class SpeakingFeedbackCard extends StatelessWidget {
  final int score;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;

  const SpeakingFeedbackCard({
    super.key,
    required this.score,
    required this.feedback,
    required this.strengths,
    required this.improvements,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 8,
                          
                          color: color,
                        ),
                      ),
                      Text(
                        '$score%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Kuchli tomonlar
            if (strengths.isNotEmpty) ...[
              const _SectionTitle(
                title: '✅ Kuchli tomonlar',
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              ...strengths.map((s) => _FeedbackItem(text: s, isPositive: true)),
              const SizedBox(height: 16),
            ],

            // Yaxshilash kerak
            if (improvements.isNotEmpty) ...[
              const _SectionTitle(
                title: '📈 Yaxshilash kerak',
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              ...improvements
                  .map((s) => _FeedbackItem(text: s, isPositive: false)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  final String text;
  final bool isPositive;

  const _FeedbackItem({required this.text, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle_outline : Icons.arrow_upward,
            size: 18,
            color: isPositive ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
