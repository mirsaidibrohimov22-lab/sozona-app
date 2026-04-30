// QO'YISH: lib/features/teacher/content_generator/presentation/screens/content_generator_screen.dart
// Content Generator Screen — AI bilan kontent yaratish ekrani

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/core/widgets/app_snackbar.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/usecases/generate_quiz.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/usecases/generate_speaking.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/usecases/generate_listening.dart';
import 'package:my_first_app/features/teacher/content_generator/presentation/providers/content_gen_provider.dart';
import 'package:my_first_app/features/teacher/content_generator/presentation/widgets/content_type_selector.dart';

/// Content Generator Screen
///
/// Bolaga: Bu ekranda teacher AI'ga "quiz/flashcard/listening yarat" deydi.
/// Tur, til, daraja, mavzu tanlaydi va AI yaratadi.
class ContentGeneratorScreen extends ConsumerStatefulWidget {
  const ContentGeneratorScreen({super.key});

  @override
  ConsumerState<ContentGeneratorScreen> createState() =>
      _ContentGeneratorScreenState();
}

class _ContentGeneratorScreenState
    extends ConsumerState<ContentGeneratorScreen> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Selected values
  ContentType _selectedType = ContentType.quiz;
  String _selectedLanguage = 'en';
  String _selectedLevel = 'A1';

  // Text controllers
  final _topicController = TextEditingController();
  final _countController = TextEditingController(text: '10');
  final _grammarController = TextEditingController();

  // Advanced options
  String _quizDifficulty = 'medium';
  String _speakingScenario = 'conversation';
  int _listeningDuration = 120;

  @override
  void dispose() {
    _topicController.dispose();
    _countController.dispose();
    _grammarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider'dan state olish
    final state = ref.watch(contentGeneratorProvider);

    // Xatolik yuz berganda SnackBar ko'rsatish
    ref.listen<ContentGeneratorState>(
      contentGeneratorProvider,
      (previous, next) {
        if (next.errorMessage != null) {
          AppSnackbar.showError(context, next.errorMessage!);
        }

        // Muvaffaqiyatli yaratilganda Preview ekraniga o'tish
        if (next.generatedContent != null && !next.isGenerating) {
          if (context.mounted) {
            context.push(
              RoutePaths.contentPreview,
              extra: next.generatedContent,
            );
          }
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Kontent Yaratish'),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Intro matn
            Text(
              'AI yordamida quiz, speaking yoki listening mashqi yarating',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Kontent turi tanlovchi
            Text('Kontent turi', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            ContentTypeSelector(
              selectedType: _selectedType,
              onTypeChanged: (type) {
                setState(() {
                  _selectedType = type;
                  _updateDefaultCount();
                });
              },
            ),
            const SizedBox(height: 24),

            // Til tanlash
            Text('Til', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'de', label: Text('Deutsch')),
              ],
              selected: {_selectedLanguage},
              onSelectionChanged: (Set<String> selected) {
                setState(() => _selectedLanguage = selected.first);
              },
            ),
            const SizedBox(height: 24),

            // Daraja tanlash
            Text('Daraja', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'A1', label: Text('A1')),
                ButtonSegment(value: 'A2', label: Text('A2')),
                ButtonSegment(value: 'B1', label: Text('B1')),
                ButtonSegment(value: 'B2', label: Text('B2')),
                ButtonSegment(value: 'C1', label: Text('C1')),
              ],
              selected: {_selectedLevel},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _selectedLevel = selected.first;
                  _updateDefaultCount();
                });
              },
            ),
            const SizedBox(height: 24),

            // Mavzu
            Text('Mavzu', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _topicController,
              decoration: const InputDecoration(
                hintText: 'Masalan: Daily Routine, Travel, Food',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mavzuni kiriting';
                }
                if (value.length < 3) {
                  return 'Mavzu kamida 3 ta belgidan iborat bo\'lishi kerak';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Miqdor (savol/kartochka soni)
            Text(_getCountLabel(), style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _countController,
              decoration: InputDecoration(
                hintText: _getCountHint(),
                border: const OutlineInputBorder(),
                suffixText: _getCountSuffix(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Sonni kiriting';
                }
                final count = int.tryParse(value);
                if (count == null || count < 1) {
                  return 'Kamida 1 bo\'lishi kerak';
                }
                if (count > _getMaxCount()) {
                  return 'Maksimal $_getMaxCount() bo\'lishi mumkin';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Advanced options (kontent turiga qarab)
            _buildAdvancedOptions(),

            const SizedBox(height: 32),

            // ✅ Generating progress info
            if (state.isGenerating) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI yaratmoqda...',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6C63FF),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bu 10-30 soniya vaqt olishi mumkin',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Yaratish tugmasi
            AppButton(
              label:
                  state.isGenerating ? 'Yaratilmoqda...' : 'AI bilan Yaratish',
              onPressed: state.isGenerating ? null : _handleGenerate,
              isLoading: state.isGenerating,
              icon: Icons.auto_awesome,
            ),
          ],
        ),
      ),
    );
  }

  /// Kontent turiga qarab default count yangilash
  void _updateDefaultCount() {
    int defaultCount;
    switch (_selectedType) {
      case ContentType.quiz:
        defaultCount =
            GenerateQuizParams.recommendedQuestionCount(_selectedLevel);
        break;
      case ContentType.speaking:
        defaultCount = 5;
        break;
      case ContentType.listening:
        defaultCount =
            GenerateListeningParams.recommendedQuestionCount(_selectedLevel);
        break;
    }
    _countController.text = defaultCount.toString();
  }

  /// Generate tugmasi bosilganda
  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    final topic = _topicController.text.trim();
    final count = int.parse(_countController.text);

    // Kontent turiga qarab tegishli UseCase'ni chaqirish
    switch (_selectedType) {
      case ContentType.quiz:
        await ref.read(contentGeneratorProvider.notifier).generateQuiz(
              GenerateQuizParams(
                language: _selectedLanguage,
                level: _selectedLevel,
                topic: topic,
                questionCount: count,
                difficulty: _quizDifficulty,
                grammar: _grammarController.text.trim(),
              ),
            );
        break;

      case ContentType.speaking:
        await ref.read(contentGeneratorProvider.notifier).generateSpeaking(
              GenerateSpeakingParams(
                language: _selectedLanguage,
                level: _selectedLevel,
                topic: topic,
              ),
            );
        break;

      case ContentType.listening:
        await ref.read(contentGeneratorProvider.notifier).generateListening(
              GenerateListeningParams(
                language: _selectedLanguage,
                level: _selectedLevel,
                topic: topic,
                duration: _listeningDuration,
                questionCount: count,
              ),
            );
        break;
    }
  }

  /// Advanced options (kontent turiga qarab)
  Widget _buildAdvancedOptions() {
    switch (_selectedType) {
      case ContentType.quiz:
        return _buildQuizOptions();
      case ContentType.speaking:
        return _buildSpeakingOptions();
      case ContentType.listening:
        return _buildListeningOptions();
    }
  }

  Widget _buildQuizOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Qiyinchilik darajasi', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'easy', label: Text('Oson')),
            ButtonSegment(value: 'medium', label: Text('O\'rta')),
            ButtonSegment(value: 'hard', label: Text('Qiyin')),
          ],
          selected: {_quizDifficulty},
          onSelectionChanged: (Set<String> selected) {
            setState(() => _quizDifficulty = selected.first);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSpeakingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suhbat stsenariyi', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'conversation', label: Text('Suhbat')),
            ButtonSegment(value: 'presentation', label: Text('Taqdimot')),
            ButtonSegment(value: 'debate', label: Text('Munozara')),
          ],
          selected: {_speakingScenario},
          onSelectionChanged: (Set<String> selected) {
            setState(() => _speakingScenario = selected.first);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildListeningOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audio davomiyligi', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 60, label: Text('1 daq')),
            ButtonSegment(value: 120, label: Text('2 daq')),
            ButtonSegment(value: 180, label: Text('3 daq')),
            ButtonSegment(value: 240, label: Text('4 daq')),
          ],
          selected: {_listeningDuration},
          onSelectionChanged: (Set<int> selected) {
            setState(() => _listeningDuration = selected.first);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Helper methods
  String _getCountLabel() {
    switch (_selectedType) {
      case ContentType.quiz:
        return 'Savollar soni';
      case ContentType.speaking:
        return 'Kartochkalar soni';
      case ContentType.listening:
        return 'Savollar soni';
    }
  }

  String _getCountHint() => 'Son kiriting';

  String _getCountSuffix() {
    switch (_selectedType) {
      case ContentType.quiz:
        return 'ta savol';
      case ContentType.speaking:
        return 'ta kartochka';
      case ContentType.listening:
        return 'ta savol';
    }
  }

  int _getMaxCount() {
    switch (_selectedType) {
      case ContentType.quiz:
        return 50;
      case ContentType.speaking:
        return 100;
      case ContentType.listening:
        return 20;
    }
  }
}
