// lib/features/student/listening/presentation/screens/listening_list_screen.dart
// So'zona — Listening List Screen
// ✅ AI orqali listening mashq yaratish dialogi qo'shildi
// ✅ O'qituvchi yuborgan + AI yaratgan mashqlar ko'rsatiladi
// ✅ Yaratilgan mashq Firestore ga saqlanib, ro'yxatga qo'shiladi

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/api_endpoints.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/listening/domain/entities/listening_exercise.dart';
import 'package:my_first_app/features/student/listening/domain/usecases/get_listening_exercises.dart';
import 'package:my_first_app/features/student/listening/presentation/providers/listening_provider.dart';

class ListeningListScreen extends ConsumerStatefulWidget {
  const ListeningListScreen({super.key});

  @override
  ConsumerState<ListeningListScreen> createState() =>
      _ListeningListScreenState();
}

class _ListeningListScreenState extends ConsumerState<ListeningListScreen> {
  String? selectedLanguage;
  String? selectedLevel;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      listeningListProvider(
        GetListeningParams(
          language: selectedLanguage,
          level: selectedLevel,
        ),
      ),
    );

    final hasFilter = selectedLanguage != null || selectedLevel != null;
    final user = ref.watch(authNotifierProvider).user;
    final lang = user?.learningLanguage.name ?? 'en';
    final level = user?.level.name ?? 'A1';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasFilter ? AppColors.primary : null,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: exercisesAsync.when(
        data: (exercises) => _buildBody(exercises, lang, level),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppEmptyWidget(
          icon: Icons.error_outline,
          title: 'Xatolik yuz berdi',
          message: error.toString(),
          actionLabel: 'Qayta urinish',
          onAction: () => ref.invalidate(listeningListProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating
            ? null
            : () => _showAiGenerateDialog(context, lang, level),
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

  Widget _buildBody(
      List<ListeningExercise> exercises, String lang, String level) {
    if (exercises.isEmpty) {
      final hasFilter = selectedLanguage != null || selectedLevel != null;
      return Column(
        children: [
          // AI banner
          _AiListeningBanner(
            isGenerating: _isGenerating,
            onTap: () => _showAiGenerateDialog(context, lang, level),
          ),
          Expanded(
            child: AppEmptyWidget(
              icon: Icons.headphones_outlined,
              title: 'Listening mashq topilmadi',
              message: hasFilter
                  ? 'Bu filtrlarga mos mashq yo\'q'
                  : 'AI yordamida yangi listening mashq yarating',
              actionLabel: hasFilter ? 'Filterlarni tozalash' : null,
              onAction: hasFilter
                  ? () => setState(() {
                        selectedLanguage = null;
                        selectedLevel = null;
                      })
                  : null,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // AI Banner
        _AiListeningBanner(
          isGenerating: _isGenerating,
          onTap: () => _showAiGenerateDialog(context, lang, level),
        ),
        const Divider(height: 1),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(listeningListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.spacingLg),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _ListeningCard(
                  exercise: exercise,
                  onTap: () =>
                      context.push(RoutePaths.listeningDetailPath(exercise.id)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AI LISTENING YARATISH DIALOGI
  // ═══════════════════════════════════════════════════════════════
  void _showAiGenerateDialog(BuildContext context, String lang, String level) {
    String selectedTopic = '';
    int questionCount = 5;
    int duration = 60;

    final topicSuggestions = lang == 'de'
        ? [
            'Im Supermarkt',
            'Am Bahnhof',
            'Im Restaurant',
            'Familie und Freunde',
            'Arbeitsalltag',
          ]
        : [
            'Daily Life',
            'Travel & Tourism',
            'Work & Business',
            'Science & Technology',
            'Health & Wellness',
            'Culture & Arts',
          ];

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
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.headphones,
                          color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Listening Mashq',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'AI audio matn va savollar yaratadi',
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

                // Mavzu
                const Text('Mavzu',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Mavzu kiriting...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.topic),
                  ),
                  onChanged: (v) => setModalState(() => selectedTopic = v),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topicSuggestions.map((t) {
                    final isSel = selectedTopic == t;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedTopic = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.orange
                              : Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel
                                ? Colors.orange
                                : Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSel ? Colors.white : Colors.orange,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Savol soni
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
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$questionCount ta',
                        style: const TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: questionCount.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 7,
                  activeColor: Colors.orange,
                  label: '$questionCount',
                  onChanged: (v) =>
                      setModalState(() => questionCount = v.round()),
                ),
                const SizedBox(height: 8),

                // Audio davomiyligi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Audio davomiyligi',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${duration ~/ 60} daqiqa',
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: duration.toDouble(),
                  min: 30,
                  max: 180,
                  divisions: 5,
                  activeColor: Colors.blue,
                  label: '${duration ~/ 60} min',
                  onChanged: (v) => setModalState(() => duration = v.round()),
                ),
                const SizedBox(height: 16),

                // Daraja
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sizning darajangiz',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.green)),
                          Text(
                            '$level — ${lang == 'de' ? 'Nemis tili' : 'Ingliz tili'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Yaratish
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _generateListening(
                        topic: selectedTopic.isNotEmpty
                            ? selectedTopic
                            : topicSuggestions.first,
                        lang: lang,
                        level: level,
                        questionCount: questionCount,
                        duration: duration,
                      );
                    },
                    icon: const Icon(Icons.headphones),
                    label: const Text(
                      'AI listening yaratish',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
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

  // ═══════════════════════════════════════════════════════════════
  // AI LISTENING YARATISH
  // ═══════════════════════════════════════════════════════════════
  Future<void> _generateListening({
    required String topic,
    required String lang,
    required String level,
    required int questionCount,
    required int duration,
  }) async {
    if (!mounted) return;
    setState(() => _isGenerating = true);

    try {
      final callable =
          FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable(
        ApiEndpoints.generateListening,
        options: HttpsCallableOptions(timeout: ApiEndpoints.longTimeout),
      );

      await callable.call({
        'language': lang,
        'level': level,
        'topic': topic,
        'questionCount': questionCount,
        'duration': duration,
      });

      if (!mounted) return;

      // Ro'yxatni yangilash
      ref.invalidate(listeningListProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening mashq yaratildi! ✅'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e.message ?? e.code)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
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
        error.contains('resource-exhausted') ||
        error.contains('quota')) {
      return 'AI hozir band. Iltimos, bir necha daqiqadan keyin urinib ko\'ring.';
    }
    if (error.contains('timeout') || error.contains('deadline-exceeded')) {
      return 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.';
    }
    if (error.length > 120) {
      return 'Listening yaratishda xatolik. Qayta urinib ko\'ring.';
    }
    return error;
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER DIALOG
  // ═══════════════════════════════════════════════════════════════
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSizes.spacingXl,
            right: AppSizes.spacingXl,
            top: AppSizes.spacingXl,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppSizes.spacingXl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filterlar',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedLanguage = null;
                        selectedLevel = null;
                      });
                      setModalState(() {});
                    },
                    child: const Text('Tozalash'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Til', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Ingliz tili'),
                    selected: selectedLanguage == 'english',
                    onSelected: (s) {
                      setState(() => selectedLanguage = s ? 'english' : null);
                      setModalState(() {});
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Nemis tili'),
                    selected: selectedLanguage == 'deutsch',
                    onSelected: (s) {
                      setState(() => selectedLanguage = s ? 'deutsch' : null);
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Daraja',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['A1', 'A2', 'B1', 'B2', 'C1'].map((l) {
                  return ChoiceChip(
                    label: Text(l),
                    selected: selectedLevel == l,
                    onSelected: (s) {
                      setState(() => selectedLevel = s ? l : null);
                      setModalState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.spacingXl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Qo\'llash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AI LISTENING BANNER
// ═══════════════════════════════════════════════════════════════
class _AiListeningBanner extends StatelessWidget {
  final bool isGenerating;
  final VoidCallback onTap;

  const _AiListeningBanner({required this.isGenerating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.deepOrange.shade400],
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
                const Text('🎧', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Listening',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGenerating
                            ? 'Yaratilmoqda...'
                            : 'Darajangizga mos audio va savollar',
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

// ═══════════════════════════════════════════════════════════════
// LISTENING CARD
// ═══════════════════════════════════════════════════════════════
class _ListeningCard extends StatelessWidget {
  final ListeningExercise exercise;
  final VoidCallback onTap;

  const _ListeningCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(Icons.headphones, color: Colors.orange),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (exercise.level.isNotEmpty)
                          _chip(exercise.level, Colors.blue),
                        const SizedBox(width: 6),
                        if (exercise.duration > 0)
                          _chip(
                              '${exercise.duration ~/ 60} min', Colors.orange),
                        const SizedBox(width: 6),
                        _chip(
                            '${exercise.questions.length} savol', Colors.green),
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

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
