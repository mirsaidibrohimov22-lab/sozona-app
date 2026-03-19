// lib/features/student/artikel/presentation/screens/artikel_practice_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/artikel/domain/entities/artikel_word.dart';
import 'package:my_first_app/features/student/artikel/presentation/providers/artikel_provider.dart';
import 'package:my_first_app/features/student/artikel/presentation/widgets/der_die_das_button.dart';

class ArtikelPracticeScreen extends ConsumerStatefulWidget {
  final List<ArtikelWord> words;
  const ArtikelPracticeScreen({super.key, required this.words});

  @override
  ConsumerState<ArtikelPracticeScreen> createState() =>
      _ArtikelPracticeScreenState();
}

class _ArtikelPracticeScreenState extends ConsumerState<ArtikelPracticeScreen> {
  int _currentIndex = 0;
  String? _selectedArtikel;
  bool? _isCorrect;
  int _score = 0;

  ArtikelWord get _current => widget.words[_currentIndex];

  void _select(String artikel) {
    if (_isCorrect != null) return;
    final correct = artikel == _current.artikel;
    setState(() {
      _selectedArtikel = artikel;
      _isCorrect = correct;
      if (correct) _score++;
    });
    final uid = ref.read(authNotifierProvider).user?.id ?? '';
    ref.read(artikelRepositoryProvider).submitAnswer(
          userId: uid,
          wordId: _current.id,
          selectedArtikel: artikel,
        );
  }

  void _next() {
    if (_currentIndex < widget.words.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedArtikel = null;
        _isCorrect = null;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Mashq tugadi!'),
        content: Text('Natija: $_score / ${widget.words.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${widget.words.length}'),
        actions: [Text('⭐ $_score  ', style: const TextStyle(fontSize: 16))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.words.length,
            ),
            const SizedBox(height: 32),
            Text(
              _current.word,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            if (_current.example != null) ...[
              const SizedBox(height: 8),
              Text(
                _current.example!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(_current.translation, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            if (_isCorrect != null) ...[
              Icon(
                _isCorrect! ? Icons.check_circle : Icons.cancel,
                size: 48,
                color: _isCorrect! ? Colors.green : Colors.red,
              ),
              Text(
                _isCorrect!
                    ? 'To\'g\'ri! ${_current.artikel} ${_current.word}'
                    : 'Noto\'g\'ri. To\'g\'risi: ${_current.artikel} ${_current.word}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['der', 'die', 'das']
                  .map(
                    (a) => DerDieDasButton(
                      artikel: a,
                      isSelected: _selectedArtikel == a,
                      isCorrect:
                          _isCorrect == null ? null : a == _current.artikel,
                      onTap: () => _select(a),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            if (_isCorrect != null)
              ElevatedButton(
                onPressed: _next,
                child: Text(
                  _currentIndex < widget.words.length - 1
                      ? 'Keyingi'
                      : 'Natijani ko\'rish',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
