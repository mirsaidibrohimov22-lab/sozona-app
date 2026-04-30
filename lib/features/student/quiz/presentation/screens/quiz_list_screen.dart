// lib/features/student/quiz/presentation/screens/quiz_list_screen.dart
// So'zona — Quizlar ro'yxati ekrani
// ✅ FIX: Grammatika ro'yxati darajaga qarab o'zgaradi (A1→C1)
// ✅ FIX: Keraksiz importlar olib tashlandi

import 'package:flutter/material.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/shimmer_loading.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/quiz/domain/entities/quiz.dart';
import 'package:my_first_app/features/student/quiz/presentation/providers/quiz_provider.dart';

class QuizListScreen extends ConsumerStatefulWidget {
  const QuizListScreen({super.key});

  @override
  ConsumerState<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends ConsumerState<QuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;
    ref.read(quizProvider.notifier).loadQuizzes(
          userId: user.id,
          // ✅ FIX: Firestore filter 'english'/'german' ishlatadi — to'g'ri
          language: user.learningLanguage.name,
          level: user.level.name.toUpperCase(),
        );
  }

  // ✅ FIX: Grammatika ro'yxati DARAJAGA QARAB — A1 dan C1 gacha
  List<String> _getGrammarTopics(String lang, String level) {
    if (lang == 'de') {
      switch (level) {
        case 'A1':
          return [
            'Artikel (der/die/das)',
            'Nominativ',
            'Personalpronomen',
            'sein / haben'
          ];
        case 'A2':
          return ['Akkusativ', 'Dativ', 'Modalverben', 'Perfekt'];
        case 'B1':
          return [
            'Praeteritum',
            'Konjunktiv II',
            'Relativsaetze',
            'Passiv Praesens'
          ];
        case 'B2':
          return [
            'Konjunktiv I',
            'Passiv Praeteritum',
            'Erweiterte Partizipien',
            'Nomen-Verb-Verbindungen'
          ];
        case 'C1':
          return [
            'Partizipialkonstruktionen',
            'Doppelkonjunktionen',
            'Nominalstil',
            'Modalpartikeln'
          ];
        default:
          return ['Grammatik'];
      }
    } else {
      switch (level) {
        case 'A1':
          return [
            'Present Simple',
            'To Be',
            'Articles (a/an/the)',
            'Basic Questions'
          ];
        case 'A2':
          return [
            'Past Simple',
            'Present Continuous',
            'Comparatives',
            'There is / There are'
          ];
        case 'B1':
          return [
            'Present Perfect',
            'Past Continuous',
            'Modal Verbs',
            'Going to / Will'
          ];
        case 'B2':
          return [
            'Conditionals (0,1,2)',
            'Passive Voice',
            'Reported Speech',
            'Wish / If only'
          ];
        case 'C1':
          return [
            'Mixed Conditionals',
            'Inversion',
            'Subjunctive Mood',
            'Cleft Sentences'
          ];
        default:
          return ['Grammar'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);
    final user = ref.watch(authNotifierProvider).user;

    ref.listen<QuizState>(quizProvider, (prev, next) {
      if (prev != null &&
          prev.isGenerating &&
          !next.isGenerating &&
          next.activeQuiz != null) {
        if (mounted) context.push(RoutePaths.quizPlay);
      }

      if (prev != null &&
          prev.isGenerating &&
          !next.isGenerating &&
          next.activeQuiz == null &&
          next.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _normalizeError(next.error!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Quiz yaratish',
            onPressed: state.isGenerating
                ? null
                : () => _showAiQuizDialog(user?.id ?? ''),
          ),
        ],
      ),
      body: Column(
        children: [
          _AiQuizBanner(
            isGenerating: state.isGenerating,
            onTap: () => _showAiQuizDialog(user?.id ?? ''),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(state, user?.id ?? '')),
        ],
      ),
    );
  }

  Widget _buildBody(QuizState state, String userId) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerList(itemCount: 5),
      );
    }
    if (state.error != null && !state.isGenerating) {
      return AppErrorWidget(message: state.error!, onRetry: _load);
    }

    final teacherQuizzes = state.teacherQuizzes;
    final myQuizzes = state.myQuizzes;

    if (teacherQuizzes.isEmpty && myQuizzes.isEmpty) {
      return AppEmptyWidget(
        title: 'Quiz topilmadi',
        message:
            "AI yordamida yangi quiz yarating yoki o'qituvchi jo'natishini kuting",
        icon: Icons.quiz_outlined,
        actionLabel: 'AI Quiz yaratish',
        onAction: () => _showAiQuizDialog(userId),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (teacherQuizzes.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.school_rounded,
              title: "O'qituvchi quizlari",
              subtitle: '${teacherQuizzes.length} ta quiz',
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            ...teacherQuizzes.map(
              (quiz) => _TeacherQuizCard(
                quiz: quiz,
                onTap: () => _openQuiz(quiz),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (myQuizzes.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.person_rounded,
              title: 'Mening quizlarim',
              subtitle: '${myQuizzes.length} ta quiz',
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            ...myQuizzes.map(
              (quiz) => _MyQuizCard(
                quiz: quiz,
                onTap: () => _openQuiz(quiz),
                onDelete: () => _confirmDelete(quiz),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _openQuiz(Quiz quiz) {
    ref.read(quizProvider.notifier).startQuiz(quiz);
    context.push(RoutePaths.quizPlay);
  }

  // ✅ AI Quiz Dialog — grammatika darajaga qarab dinamik
  void _showAiQuizDialog(String userId) {
    if (userId.isEmpty) return;
    final user = ref.read(authNotifierProvider).user;
    // ✅ FIX: enum nomi 'german'→'de', 'english'→'en' (Cloud Function uchun)
    final lang = user?.learningLanguage.name == 'german' ? 'de' : 'en';
    final userLevel = user?.level.name.toUpperCase() ?? 'A1';

    String selectedTopic = '';
    String selectedGrammar = '';
    String selectedLevel = userLevel;
    int questionCount = 10;
    final topicController = TextEditingController();
    final grammarController = TextEditingController();

    final topicSuggestions = lang == 'de'
        ? [
            'Im Supermarkt',
            'Am Bahnhof',
            'Im Restaurant',
            'Familie und Freunde',
            'Arbeitsalltag',
            'Reisen und Urlaub',
            'Sport und Freizeit',
            'Gesundheit',
            'Schule und Bildung',
            'Technologie',
            'Natur und Umwelt',
            'Kultur und Kunst',
            'Wohnen',
            'Einkaufen',
            'Essen und Trinken',
          ]
        : [
            'Daily Life',
            'Travel & Tourism',
            'Work & Business',
            'Health & Wellness',
            'Science & Technology',
            'Culture & Arts',
            'Sports & Hobbies',
            'Food & Cooking',
            'Education',
            'Environment',
            'Shopping',
            'Music & Movies',
            'Family & Relationships',
            'Social Media',
            'History',
            'Animals & Nature',
            'Cities & Transport',
          ];

    final levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // ✅ Grammatika ro'yxati tanlangan darajaga qarab yangilanadi
          final grammarTopics = _getGrammarTopics(lang, selectedLevel);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              const Color(0xFF7C4DFF)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Quiz Yaratish',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Shaxsiylashtirilgan quiz',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Daraja ──
                  const Text('Daraja',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: levels.map((l) {
                        final isSel = selectedLevel == l;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setModalState(() {
                              selectedLevel = l;
                              // Daraja o'zgarganda grammatika tanlovini tozalash
                              selectedGrammar = '';
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                l,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Mavzu ──
                  const Text('Mavzu',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: topicController,
                    decoration: InputDecoration(
                      hintText: 'Masalan: Sports, Essen, Technology...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.topic_outlined),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setModalState(() => selectedTopic = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topicSuggestions.map((t) {
                      final isSel = selectedTopic == t;
                      return GestureDetector(
                        onTap: () => setModalState(() {
                          selectedTopic = t;
                          topicController.text = t;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : Colors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : Colors.purple)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Grammatika (darajaga qarab) ──
                  Row(
                    children: [
                      const Text('Grammatika (ixtiyoriy)',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          selectedLevel,
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: grammarController,
                    decoration: InputDecoration(
                      hintText: 'O\'zingiz yozing yoki pastdan tanlang...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.spellcheck),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setModalState(() => selectedGrammar = v),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: grammarTopics.map((g) {
                      final isSel = selectedGrammar == g;
                      return GestureDetector(
                        onTap: () => setModalState(() {
                          selectedGrammar = isSel ? '' : g;
                          grammarController.text = selectedGrammar;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? Colors.teal
                                : Colors.teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel
                                  ? Colors.teal
                                  : Colors.teal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(g,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : Colors.teal)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Savol soni ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Savol soni',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$questionCount ta',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  Slider(
                    value: questionCount.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 15,
                    activeColor: AppColors.primary,
                    label: '$questionCount',
                    onChanged: (v) =>
                        setModalState(() => questionCount = v.round()),
                  ),
                  const SizedBox(height: 20),

                  // ── Yaratish tugmasi ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref
                            .read(quizProvider.notifier)
                            .generateAiQuizWithParams(
                              userId: userId,
                              language: lang,
                              level: selectedLevel,
                              topic: selectedTopic.isNotEmpty
                                  ? selectedTopic
                                  : topicSuggestions.first,
                              grammar: selectedGrammar,
                              questionCount: questionCount,
                            );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI Quiz Yaratish',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      topicController.dispose();
      grammarController.dispose();
    });
  }

  Future<void> _confirmDelete(Quiz quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Quizni o'chirish"),
        content: Text('"${quiz.title}" quizini o\'chirishni tasdiqlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text("O'chirish", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(quizProvider.notifier).deleteQuiz(quiz.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${quiz.title}" o\'chirildi'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _normalizeError(String error) {
    if (error.contains('429') || error.contains('Too Many Requests')) {
      return 'AI hozir band. Bir necha daqiqadan keyin qayta urinib ko\'ring.';
    }
    if (error.contains('quota') || error.contains('exceeded')) {
      return 'AI so\'rovlar limiti tugadi. Keyinroq qayta urinib ko\'ring.';
    }
    if (error.contains('permission-denied')) {
      return 'Ruxsat berilmadi. Qayta login qiling.';
    }
    if (error.contains('unavailable') || error.contains('network')) {
      return 'Internet aloqasi yo\'q.';
    }
    if (error.contains('timeout')) {
      return 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.';
    }
    if (error.length > 100) {
      return 'Quiz yaratishda xatolik. Qayta urinib ko\'ring.';
    }
    return error;
  }
}

// ─── Section Header ───
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _SectionHeader(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── O'qituvchi Quiz Kartasi ───
class _TeacherQuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;
  const _TeacherQuizCard({required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final xpReward = quiz.totalPoints ~/ 2;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      _Chip(label: quiz.level, color: Colors.blue),
                      const SizedBox(width: 6),
                      _Chip(
                          label: '${quiz.questions.length} savol',
                          color: Colors.green),
                      const SizedBox(width: 6),
                      _Chip(label: '30s/savol', color: Colors.orange),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Text('+$xpReward XP',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.amber.shade800)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mening Quiz Kartasi ───
class _MyQuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _MyQuizCard(
      {required this.quiz, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAi = quiz.generatedByAi;
    final gradientColors = isAi
        ? [AppColors.primary, const Color(0xFF7C4DFF)]
        : [Colors.teal.shade600, Colors.teal.shade400];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isAi ? Icons.auto_awesome : Icons.edit_note_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(quiz.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      if (isAi)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('AI',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      _Chip(
                          label: quiz.level,
                          color: isAi ? AppColors.primary : Colors.teal),
                      const SizedBox(width: 6),
                      if (quiz.topic.isNotEmpty && quiz.topic != 'adaptive')
                        _Chip(label: quiz.topic, color: Colors.grey),
                      const SizedBox(width: 6),
                      _Chip(
                          label: '${quiz.questions.length} savol',
                          color: Colors.green),
                    ]),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 22),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── AI Quiz Banner ───
class _AiQuizBanner extends StatelessWidget {
  final bool isGenerating;
  final VoidCallback onTap;
  const _AiQuizBanner({required this.isGenerating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGenerating ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Quiz',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        isGenerating
                            ? 'Yaratilmoqda...'
                            : 'Zaif joylaring asosida shaxsiy quiz',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (isGenerating)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
