// lib/features/premium/presentation/screens/book_reader_screen.dart
// So'zona — Kitob o'qish ekrani
// ✅ AI Murabbiy integratsiyasi:
//    - Mashq xato javoblari AI ga yuboriladi
//    - AI tushuntirish beradi
//    - Xatolar AI Murabbiy provideriga yoziladi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/data/services/book_service.dart';
import 'package:my_first_app/features/premium/presentation/providers/book_provider.dart';
import 'package:my_first_app/features/student/ai_tutor/presentation/providers/ai_tutor_provider.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final String level;
  const BookReaderScreen({super.key, required this.level});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _chapterIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(userLanguageProvider);
    final state = ref.watch(bookFamilyProvider((language, widget.level)));

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text('Kitob yuklanmoqda...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
                const SizedBox(height: 16),
                Text(state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref
                      .read(
                          bookFamilyProvider((language, widget.level)).notifier)
                      .load(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Qayta urinish'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // FIX: state.book local variable ga olinadi
    // Dart property (state.book) null check dan keyin narrowing qilmaydi
    final book = state.book;
    if (book == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A1A),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
      );
    }
    final chapter = book.chapters[_chapterIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.level,
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text(book.title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          // ✅ AI Murabbiyga savol tugmasi
          IconButton(
            icon: const Icon(Icons.psychology, color: Color(0xFFFFD700)),
            tooltip: 'AI Murabbiyga savol',
            onPressed: () => _askAiTutor(context, chapter),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // Bob tanlash
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: book.chapters.length,
                  itemBuilder: (context, i) {
                    final isSel = i == _chapterIndex;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _chapterIndex = i;
                        _tabController.animateTo(0);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isSel
                              ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFFFFD700)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          '${i + 1}-bob',
                          style: TextStyle(
                            color: isSel
                                ? const Color(0xFFFFD700)
                                : Colors.white54,
                            fontSize: 12,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFFFFD700),
                unselectedLabelColor: Colors.white38,
                indicatorColor: const Color(0xFFFFD700),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Grammar'),
                  Tab(text: "So'zlar"),
                  Tab(text: 'Dialog'),
                  Tab(text: "O'qish"),
                  Tab(text: 'Mashqlar'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GrammarTab(
              grammar: chapter.grammar,
              onAsk: () => _askAiTutor(context, chapter)),
          _VocabularyTab(vocabulary: chapter.vocabulary),
          _DialogueTab(dialogue: chapter.dialogue),
          _ReadingTab(title: chapter.readingTitle, text: chapter.readingText),
          // ✅ Mashqlar tabiga AI integratsiyasi beriladi
          _ExercisesTab(
            exercises: chapter.exercises,
            chapterTitle: chapter.title,
            bookLevel: book.level,
            language: ref.read(userLanguageProvider),
            onMistakesRecorded: (wrongAnswers) => _sendMistakesToAi(
                context, wrongAnswers, chapter.title, book.level),
          ),
        ],
      ),
    );
  }

  /// Grammar haqida AI Murabbiyga savol berish
  void _askAiTutor(BuildContext context, BookChapter chapter) {
    final grammarTopic = chapter.grammar.title;
    final level = widget.level.toUpperCase();
    context.push(
      RoutePaths.aiChat,
      extra: {
        'initialMessage':
            'Menga "$grammarTopic" grammatikasini $level darajasida tushuntir. Misollar bilan.',
      },
    );
  }

  /// Xato javoblarni AI Murabbiyga yuborish
  Future<void> _sendMistakesToAi(
    BuildContext context,
    List<Map<String, String>> wrongAnswers,
    String chapterTitle,
    String bookLevel,
  ) async {
    if (wrongAnswers.isEmpty) return;

    // 1. AI Tutor provideriga xatolarni yozish
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      for (final wrong in wrongAnswers) {
        await ref.read(aiTutorProvider.notifier).recordMistake(
              contentId:
                  'book_${widget.level}_${chapterTitle.replaceAll(' ', '_')}',
              contentType: 'book_exercise',
              userAnswer: wrong['userAnswer'] ?? '',
              correctAnswer: wrong['correctAnswer'] ?? '',
              scorePercent: 0,
            );
      }
    }

    // 2. AI Chat orqali tushuntirish olish
    if (!context.mounted) return;

    final wrongText = wrongAnswers
        .map((w) =>
            '• Savol: "${w['question']}"\n  Men yozdim: "${w['userAnswer']}"\n  To\'g\'ri: "${w['correctAnswer']}"')
        .join('\n\n');

    context.push(
      RoutePaths.aiChat,
      extra: {
        'initialMessage':
            'Men "$chapterTitle" bobidagi mashqlarda quyidagi xatolarni qildim ($bookLevel darajasi):\n\n$wrongText\n\nIltimos, bu xatolarimni tushuntir va to\'g\'ri qoidani yod olishim uchun yordam ber.',
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRAMMAR TAB
// ═══════════════════════════════════════════════════════════════

class _GrammarTab extends StatelessWidget {
  final BookGrammar grammar;
  final VoidCallback onAsk;

  const _GrammarTab({required this.grammar, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
            border: Border.all(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(grammar.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(grammar.explanation,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.7)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ✅ AI dan tushuntirish so'rash
        GestureDetector(
          onTap: onAsk,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFFFD700).withValues(alpha: 0.08),
              border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, color: Color(0xFFFFD700), size: 18),
                SizedBox(width: 8),
                Text(
                  'AI Murabbiydan tushuntirish so\'rang',
                  style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text('💡 Misollar',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...grammar.examples.map((ex) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Text('✅ ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(ex,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VOCABULARY TAB
// ═══════════════════════════════════════════════════════════════

class _VocabularyTab extends StatefulWidget {
  final List<BookVocabulary> vocabulary;
  const _VocabularyTab({required this.vocabulary});

  @override
  State<_VocabularyTab> createState() => _VocabularyTabState();
}

class _VocabularyTabState extends State<_VocabularyTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.vocabulary
        .where((v) =>
            v.word.toLowerCase().contains(_search.toLowerCase()) ||
            v.translation.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'So\'z qidirish...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              prefixIcon: Icon(Icons.search,
                  color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _VocabCard(vocab: filtered[i]),
          ),
        ),
      ],
    );
  }
}

class _VocabCard extends StatefulWidget {
  final BookVocabulary vocab;
  const _VocabCard({required this.vocab});

  @override
  State<_VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends State<_VocabCard> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _show = !_show),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.vocab.word,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                Text(widget.vocab.translation,
                    style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        fontSize: 14)),
                const SizedBox(width: 8),
                Icon(_show ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38, size: 18),
              ],
            ),
            if (_show) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
                child: Text(widget.vocab.example,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DIALOGUE TAB
// ═══════════════════════════════════════════════════════════════

class _DialogueTab extends StatelessWidget {
  final BookDialogue dialogue;
  const _DialogueTab({required this.dialogue});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('💬 ${dialogue.title}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...dialogue.lines.asMap().entries.map((e) {
          final isLeft = e.key % 2 == 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment:
                  isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                  child: Text(e.value.speaker,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          isLeft ? Radius.zero : const Radius.circular(16),
                      bottomRight:
                          isLeft ? const Radius.circular(16) : Radius.zero,
                    ),
                    color: isLeft
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: Text(e.value.text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// READING TAB
// ═══════════════════════════════════════════════════════════════

class _ReadingTab extends StatelessWidget {
  final String title;
  final String text;
  const _ReadingTab({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('📖 $title',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.8)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXERCISES TAB — AI integratsiyasi bilan
// ═══════════════════════════════════════════════════════════════

class _ExercisesTab extends StatelessWidget {
  final List<BookExercise> exercises;
  final String chapterTitle;
  final String bookLevel;
  final String language;
  final Function(List<Map<String, String>>) onMistakesRecorded;

  const _ExercisesTab({
    required this.exercises,
    required this.chapterTitle,
    required this.bookLevel,
    required this.language,
    required this.onMistakesRecorded,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('✏️ Mashqlar',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...exercises.map((ex) => _ExerciseWidget(
              exercise: ex,
              chapterTitle: chapterTitle,
              bookLevel: bookLevel,
              onMistakesRecorded: onMistakesRecorded,
            )),
      ],
    );
  }
}

class _ExerciseWidget extends StatefulWidget {
  final BookExercise exercise;
  final String chapterTitle;
  final String bookLevel;
  final Function(List<Map<String, String>>) onMistakesRecorded;

  const _ExerciseWidget({
    required this.exercise,
    required this.chapterTitle,
    required this.bookLevel,
    required this.onMistakesRecorded,
  });

  @override
  State<_ExerciseWidget> createState() => _ExerciseWidgetState();
}

class _ExerciseWidgetState extends State<_ExerciseWidget> {
  final Map<int, String> _answers = {};
  final Map<int, bool?> _results = {};
  bool _submitted = false;
  bool _aiSent = false; // AI ga yuborilganmi

  void _check() {
    final wrongAnswers = <Map<String, String>>[];

    setState(() {
      _submitted = true;
      for (int i = 0; i < widget.exercise.questions.length; i++) {
        final q = widget.exercise.questions[i];
        final ans = _answers[i] ?? '';
        final isCorrect =
            ans.trim().toLowerCase() == q.answer.trim().toLowerCase();
        _results[i] = isCorrect;

        if (!isCorrect) {
          wrongAnswers.add({
            'question': q.question,
            'userAnswer': ans.isEmpty ? '(bo\'sh)' : ans,
            'correctAnswer': q.answer,
          });
        }
      }
    });

    // Xatolar bo'lsa AI ga yuborish taklifi
    if (wrongAnswers.isNotEmpty && !_aiSent) {
      _wrongAnswers = wrongAnswers;
    }
  }

  List<Map<String, String>> _wrongAnswers = [];

  void _reset() {
    setState(() {
      _answers.clear();
      _results.clear();
      _submitted = false;
      _aiSent = false;
      _wrongAnswers = [];
    });
  }

  void _sendToAi() {
    setState(() => _aiSent = true);
    widget.onMistakesRecorded(_wrongAnswers);
  }

  int get _correctCount => _results.values.where((r) => r == true).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.exercise.instruction,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 14),

          // Savollar
          ...widget.exercise.questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final result = _results[i];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ${q.question}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),

                  // Multiple choice yoki text input
                  if (q.options.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: q.options.map((opt) {
                        Color c;
                        if (_submitted && opt == q.answer) {
                          c = const Color(0xFF22C55E);
                        } else if (_submitted &&
                            _answers[i] == opt &&
                            opt != q.answer) {
                          c = const Color(0xFFEF4444);
                        } else if (_answers[i] == opt) {
                          c = AppColors.primary;
                        } else {
                          c = Colors.white24;
                        }
                        return GestureDetector(
                          onTap: _submitted
                              ? null
                              : () => setState(() => _answers[i] = opt),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: c.withValues(alpha: 0.15),
                              border: Border.all(color: c),
                            ),
                            child: Text(opt,
                                style: TextStyle(color: c, fontSize: 13)),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    TextField(
                      onChanged: (v) => setState(() => _answers[i] = v),
                      enabled: !_submitted,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Javob...',
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30)),
                        filled: true,
                        fillColor: result == true
                            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                            : result == false
                                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        suffixIcon: result != null
                            ? Icon(result ? Icons.check_circle : Icons.cancel,
                                color: result
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFEF4444))
                            : null,
                      ),
                    ),

                  if (_submitted && result == false) ...[
                    const SizedBox(height: 4),
                    Text('✅ To\'g\'ri: ${q.answer}',
                        style: const TextStyle(
                            color: Color(0xFF22C55E), fontSize: 12)),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 4),

          // Tekshirish / Natija
          if (!_submitted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _check,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tekshirish'),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            '$_correctCount/${widget.exercise.questions.length} to\'g\'ri',
                            style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Qayta'),
                    ),
                  ],
                ),

                // ✅ Xatolar bo'lsa — AI Murabbiyga yuborish tugmasi
                if (_wrongAnswers.isNotEmpty && !_aiSent) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _sendToAi,
                      icon: const Icon(Icons.psychology,
                          color: Color(0xFFFFD700), size: 18),
                      label: const Text(
                        'AI Murabbiydan tushuntirish so\'rang',
                        style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],

                // ✅ Yuborilganidan keyin
                if (_aiSent) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                      border: Border.all(
                          color:
                              const Color(0xFFFFD700).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology,
                            color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'AI Murabbiy chat ochildi ✓',
                          style:
                              TextStyle(color: Color(0xFFFFD700), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
