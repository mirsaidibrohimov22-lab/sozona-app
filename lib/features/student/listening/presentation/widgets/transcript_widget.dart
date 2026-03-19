// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Transcript Widget
// QO'YISH: lib/features/student/listening/presentation/widgets/transcript_widget.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

/// Transcript Widget — audio matnini ko'rsatish
class TranscriptWidget extends StatelessWidget {
  final String transcript;
  final int? currentPosition;

  const TranscriptWidget({
    super.key,
    required this.transcript,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_snippet_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Transkript',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              transcript,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
