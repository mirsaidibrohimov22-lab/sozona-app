// lib/features/student/speaking/presentation/widgets/recording_button.dart
import 'package:flutter/material.dart';

class RecordingButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const RecordingButton({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isRecording) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(RecordingButton old) {
    super.didUpdateWidget(old);
    if (widget.isRecording && !old.isRecording) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && old.isRecording) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          widget.isRecording ? widget.onStopRecording : widget.onStartRecording,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isRecording ? Colors.red : Colors.blue,
            boxShadow: widget.isRecording
                ? [
                    BoxShadow(
                      color:
                          Colors.red.withValues(alpha: 0.3 + _controller.value * 0.4),
                      blurRadius: 12 + _controller.value * 20,
                      spreadRadius: 2 + _controller.value * 8,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            widget.isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
