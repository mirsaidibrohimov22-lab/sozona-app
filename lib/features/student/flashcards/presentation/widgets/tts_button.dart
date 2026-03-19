// lib/features/student/flashcards/presentation/widgets/tts_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsButton extends StatefulWidget {
  final String text;
  final String language;
  final double size;
  const TtsButton({
    super.key,
    required this.text,
    this.language = 'de-DE',
    this.size = 24,
  });
  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  final _tts = FlutterTts();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() => setState(() => _speaking = false));
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }
    await _tts.setLanguage(widget.language);
    await _tts.setSpeechRate(0.8);
    setState(() => _speaking = true);
    await _tts.speak(widget.text);
  }

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          _speaking ? Icons.volume_up : Icons.volume_up_outlined,
          size: widget.size,
          color: _speaking ? Theme.of(context).colorScheme.primary : null,
        ),
        onPressed: _speak,
        tooltip: 'Tinglash',
      );
}
