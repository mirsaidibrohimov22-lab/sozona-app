// QO'YISH: lib/features/student/quiz/presentation/widgets/fill_blank_widget.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/core/constants/app_colors.dart';

class FillBlankWidget extends StatefulWidget {
  final Function(String) onAnswer;
  final bool isAnswered;
  const FillBlankWidget({
    super.key,
    required this.onAnswer,
    required this.isAnswered,
  });

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          enabled: !widget.isAnswered,
          decoration: InputDecoration(
            hintText: 'Javobingizni kiriting...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) widget.onAnswer(v.trim());
          },
        ),
        const SizedBox(height: 12),
        if (!widget.isAnswered)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_ctrl.text.trim().isNotEmpty) {
                  widget.onAnswer(_ctrl.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Tasdiqlash',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
