// lib/features/student/speaking/presentation/screens/speaking_list_screen.dart
// So'zona — Speaking List Screen
// ✅ AI yaratish dialogi to'liq implementatsiya qilindi
// ✅ O'qituvchi yuborgan + o'zi yaratgan mashqlar ko'rsatiladi
// ✅ Yaratilgandan so'ng sessiya boshlanadi va navigate qilinadi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/speaking/domain/entities/speaking_exercise.dart';
import 'package:my_first_app/features/student/speaking/domain/usecases/get_speaking_exercises.dart';
import 'package:my_first_app/features/student/speaking/presentation/providers/speaking_provider.dart';

class SpeakingListScreen extends ConsumerStatefulWidget {
  const SpeakingListScreen({super.key});

  @override
  ConsumerState<SpeakingListScreen> createState() => _SpeakingListScreenState();
}

class _SpeakingListScreenState extends ConsumerState<SpeakingListScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).user;
    final lang = user?.learningLanguage.name ?? 'en';
    final level = user?.level.name ?? 'A1';

    final exercisesAsync = ref.watch(
      speakingListProvider(const GetSpeakingParams()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaking Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI bilan yaratish',
            onPressed: _isGenerating
                ? null
                : () => _showGenerateDialog(context, lang, level),
          ),
        ],
      ),
      body: exercisesAsync.when(
        data: (exercises) => _buildBody(exercises, context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Xatolik yuz berdi',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating
            ? null
            : () => _showGenerateDialog(context, lang, level),
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isGenerating ? 'Yaratilmoqda...' : 'AI bilan yaratish'),
        backgroundColor: _isGenerating ? Colors.grey : AppColors.primary,
      ),
    );
  }

  Widget _buildBody(List<SpeakingExercise> exercises, BuildContext context) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Speaking mashq topilmadi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "AI yordamida yangi mashq yarating\nyoki o'qituvchingiz vazifa yuborishini kuting",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final user = ref.read(authNotifierProvider).user;
                _showGenerateDialog(
                  context,
                  user?.learningLanguage.name ?? 'en',
                  user?.level.name ?? 'A1',
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI bilan yaratish'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // AI Banner
        _AiSpeakingBanner(
          isGenerating: _isGenerating,
          onTap: () {
            final user = ref.read(authNotifierProvider).user;
            _showGenerateDialog(
              context,
              user?.learningLanguage.name ?? 'en',
              user?.level.name ?? 'A1',
            );
          },
        ),
        const Divider(height: 1),
        // Mashqlar ro'yxati
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(speakingListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _SpeakingCard(
                  exercise: exercise,
                  onTap: () => _startExercise(exercise),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _startExercise(SpeakingExercise exercise) {
    ref.read(speakingSessionProvider.notifier).startSession(exercise);
    context.push(RoutePaths.speakingSessionPath(exercise.id));
  }

  // ═══════════════════════════════════════════════════════════════
  // AI YARATISH DIALOGI — to'liq implementatsiya
  // ═══════════════════════════════════════════════════════════════
  void _showGenerateDialog(BuildContext context, String lang, String level) {
    String selectedTopic = '';
    String selectedTaskType = 'describe';

    // Mavzu takliflari
    final topicSuggestions = lang == 'de'
        ? ['Alltag', 'Familie', 'Arbeit', 'Hobbys', 'Reisen', 'Essen']
        : [
            'Daily Routine',
            'My Family',
            'Travel',
            'Work & Career',
            'Hobbies',
            'Food & Culture',
            'City Life',
            'My Goals',
          ];

    final taskTypes = {
      'describe': 'Tasvirlash (Describe)',
      'opinion': 'Fikr bildirish (Opinion)',
      'narrate': 'Hikoya qilish (Narrate)',
      'roleplay': 'Rol o\'ynash (Roleplay)',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Speaking Mashq',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'AI siz uchun shaxsiy mashq yaratadi',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Mavzu yozish
                const Text('Mavzu',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Mavzu kiriting yoki quyidan tanlang...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.topic),
                  ),
                  onChanged: (v) => setModalState(() => selectedTopic = v),
                ),
                const SizedBox(height: 12),

                // Mavzu takliflari
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topicSuggestions.map((t) {
                    final isSelected = selectedTopic == t;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedTopic = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Task turi
                const Text('Mashq turi',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                ...taskTypes.entries.map((e) {
                  final isSelected = selectedTaskType == e.key;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedTaskType = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _taskTypeIcon(e.key),
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            e.value,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Daraja ko'rsatish
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sizning darajangiz',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.blue)),
                          Text(
                            '$level — ${lang == 'de' ? 'Nemis tili' : 'Ingliz tili'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Yaratish tugmasi
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _generateAndStart(
                        topic: selectedTopic.isNotEmpty
                            ? selectedTopic
                            : topicSuggestions.first,
                        lang: lang,
                        level: level,
                        taskType: selectedTaskType,
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text(
                      'AI mashq yaratish',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
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
        ),
      ),
    );
  }

  IconData _taskTypeIcon(String type) {
    switch (type) {
      case 'describe':
        return Icons.image_outlined;
      case 'opinion':
        return Icons.lightbulb_outline;
      case 'narrate':
        return Icons.auto_stories_outlined;
      case 'roleplay':
        return Icons.people_outline;
      default:
        return Icons.mic_outlined;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AI MASHQ YARATISH VA SESSIYANI BOSHLASH
  // ═══════════════════════════════════════════════════════════════
  Future<void> _generateAndStart({
    required String topic,
    required String lang,
    required String level,
    required String taskType,
  }) async {
    if (!mounted) return;
    setState(() => _isGenerating = true);

    try {
      final repo = ref.read(speakingRepositoryImplProvider);
      final result = await repo.generateDialog(
        topic: topic,
        language: lang,
        level: level,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_normalizeError(failure.message)),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        (exercise) {
          // Sessiyani boshlash va navigatsiya
          ref.read(speakingSessionProvider.notifier).startSession(exercise);
          context.push(RoutePaths.speakingSessionPath(exercise.id));
          // Ro'yxatni yangilash
          ref.invalidate(speakingListProvider);
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e.toString())),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _normalizeError(String error) {
    if (error.contains('429') ||
        error.contains('quota') ||
        error.contains('resource-exhausted')) {
      return 'AI hozir band. Iltimos, bir necha daqiqadan keyin urinib ko\'ring.';
    }
    if (error.contains('timeout') || error.contains('deadline-exceeded')) {
      return 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.';
    }
    if (error.contains('unauthenticated')) {
      return 'Iltimos, qayta login qiling.';
    }
    if (error.length > 120) {
      return 'Speaking mashq yaratishda xatolik. Qayta urinib ko\'ring.';
    }
    return error;
  }
}

// ═══════════════════════════════════════════════════════════════
// AI BANNER WIDGET
// ═══════════════════════════════════════════════════════════════
class _AiSpeakingBanner extends StatelessWidget {
  final bool isGenerating;
  final VoidCallback onTap;

  const _AiSpeakingBanner({required this.isGenerating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            Colors.teal.shade400,
          ],
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
                const Text('🎤', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Speaking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGenerating
                            ? 'Mashq yaratilmoqda...'
                            : 'AI bilan dialog o\'tkazing va baho oling',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
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

// ═══════════════════════════════════════════════════════════════
// SPEAKING EXERCISE CARD
// ═══════════════════════════════════════════════════════════════
class _SpeakingCard extends StatelessWidget {
  final SpeakingExercise exercise;
  final VoidCallback onTap;

  const _SpeakingCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.mic, color: Colors.teal, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.topic,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(exercise.level, Colors.blue),
                        const SizedBox(width: 6),
                        _Chip('${exercise.turns.length} turn', Colors.orange),
                        const SizedBox(width: 6),
                        if (exercise.language == 'de')
                          _Chip('Nemis', Colors.purple)
                        else
                          _Chip('Ingliz', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      );
}
