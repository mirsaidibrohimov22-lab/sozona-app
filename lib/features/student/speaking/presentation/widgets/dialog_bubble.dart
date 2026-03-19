// ═══════════════════════════════════════════════════════════════
// SO'ZONA — Dialog Bubble Widget
// QO'YISH: lib/features/student/speaking/presentation/widgets/dialog_bubble.dart
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';

class DialogBubble extends StatefulWidget {
  final DialogTurn turn;
  final String? userMessage;
  final bool isCurrentTurn;

  const DialogBubble({
    super.key,
    required this.turn,
    this.userMessage,
    this.isCurrentTurn = false,
  });

  @override
  State<DialogBubble> createState() => _DialogBubbleState();
}

class _DialogBubbleState extends State<DialogBubble> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.turn.isStudentTurn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isStudent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isStudent) _buildAvatar(isStudent),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isStudent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isStudent ? AppColors.primary : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isStudent ? 16 : 4),
                      bottomRight: Radius.circular(isStudent ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Partner matni yoki student javob/suggestion
                      Text(
                        isStudent
                            ? (widget.userMessage ??
                                widget.turn.suggestion ??
                                '...')
                            : (widget.turn.text ?? ''),
                        style: TextStyle(
                          color: isStudent ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),

                      // Tarjima (partner uchun)
                      if (!isStudent &&
                          widget.turn.translation != null &&
                          _showTranslation) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.turn.translation!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Ko'mak tugmalar (partner turn uchun)
                if (!isStudent) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (widget.turn.translation != null)
                        _SmallButton(
                          label: _showTranslation ? 'Yashir' : 'Tarjima',
                          icon: Icons.translate,
                          onTap: () => setState(
                            () => _showTranslation = !_showTranslation,
                          ),
                        ),
                      if (widget.turn.tips != null) ...[
                        const SizedBox(width: 8),
                        _SmallButton(
                          label: 'Maslahat',
                          icon: Icons.lightbulb_outline,
                          onTap: () => _showTip(context),
                        ),
                      ],
                    ],
                  ),
                ],

                // Alternatives (student turn uchun, userMessage bo'lmasa)
                if (isStudent &&
                    widget.userMessage == null &&
                    widget.turn.alternatives != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: widget.turn.alternatives!
                        .map(
                          (alt) => Chip(
                            label: Text(
                              alt,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isStudent) _buildAvatar(isStudent),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isStudent) {
    return CircleAvatar(
      radius: 18,
      backgroundColor:
          isStudent ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey[200],
      child: Icon(
        isStudent ? Icons.person : Icons.smart_toy,
        size: 20,
        color: isStudent ? AppColors.primary : Colors.grey[700],
      ),
    );
  }

  void _showTip(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Maslahat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(widget.turn.tips ?? ''),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
