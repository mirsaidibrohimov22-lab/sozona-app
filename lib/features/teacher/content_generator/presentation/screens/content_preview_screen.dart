// QO'YISH: lib/features/teacher/content_generator/presentation/screens/content_preview_screen.dart
// Content Preview Screen — Yaratilgan kontentni ko'rish va TAHRIRLASH

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';

/// Content Preview Screen
class ContentPreviewScreen extends ConsumerStatefulWidget {
  final GeneratedContent content;

  const ContentPreviewScreen({
    super.key,
    required this.content,
  });

  @override
  ConsumerState<ContentPreviewScreen> createState() =>
      _ContentPreviewScreenState();
}

class _ContentPreviewScreenState extends ConsumerState<ContentPreviewScreen> {
  late GeneratedContent _content;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${_content.type.displayName}'),
        foregroundColor: Colors.white,
        actions: [
          // Tahrirlash tugmasi
          TextButton.icon(
            onPressed: _toggleEditMode,
            icon: Icon(
              _isEditMode ? Icons.visibility : Icons.edit,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _isEditMode ? 'Ko\'rish' : 'Tahrirlash',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.bgTertiary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIcon(_content.type),
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _content.topic,
                            style: AppTextStyles.titleLarge,
                          ),
                          Text(
                            '${_content.language.toUpperCase()} • ${_content.level}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      _getCountLabel(_content.type),
                      _getCountValue(_content),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip('AI Model', _content.aiModel),
                    if (_isEditMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit,
                                size: 12, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text('Tahrirlash rejimi',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Content preview / edit
          Expanded(
            child: _isEditMode
                ? _buildEditView(_content)
                : _buildContentPreview(_content),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _toggleEditMode(),
                      child: Text(_isEditMode ? 'Saqlash' : 'Tahrirlash'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Sinfga Yuborish',
                      onPressed: () => _handlePublish(context),
                      icon: Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }

  /// Edit view — tahrirlash uchun
  Widget _buildEditView(GeneratedContent content) {
    switch (content.type) {
      case ContentType.quiz:
        return _buildQuizEditView(content);
      case ContentType.speaking:
        return _buildSpeakingEditView(content);
      case ContentType.listening:
        return _buildListeningEditView(content);
    }
  }

  /// Quiz tahrirlash
  Widget _buildQuizEditView(GeneratedContent content) {
    final questions =
        List<Map<String, dynamic>>.from(content.data['questions'] ?? []);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final q = Map<String, dynamic>.from(questions[index]);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Savol ${index + 1}',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Savol matni tahrirlash
                TextFormField(
                  initialValue: q['question'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Savol matni',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (val) {
                    questions[index]['question'] = val;
                    _updateQuizData(questions);
                  },
                ),
                const SizedBox(height: 8),
                // Variantlar
                ...List.generate((q['options'] as List? ?? []).length,
                    (optIdx) {
                  final opt = (q['options'] as List)[optIdx].toString();
                  final isCorrect = opt == q['correctAnswer'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            questions[index]['correctAnswer'] =
                                (questions[index]['options'] as List)[optIdx];
                            _updateQuizData(questions);
                          },
                          child: Icon(
                            isCorrect
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: isCorrect ? AppColors.success : Colors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: opt,
                            decoration: InputDecoration(
                              labelText: 'Variant ${optIdx + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              final wasCorrect =
                                  questions[index]['correctAnswer'] == opt;
                              (questions[index]['options'] as List)[optIdx] =
                                  val;
                              if (wasCorrect) {
                                questions[index]['correctAnswer'] = val;
                              }
                              _updateQuizData(questions);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateQuizData(List<Map<String, dynamic>> questions) {
    final newData = Map<String, dynamic>.from(_content.data);
    newData['questions'] = questions;
    setState(() {
      _content = _content.copyWith(data: newData);
    });
  }

  /// Listening tahrirlash
  Widget _buildListeningEditView(GeneratedContent content) {
    final transcript = content.data['transcript'] as String? ?? '';
    final questions =
        List<Map<String, dynamic>>.from(content.data['questions'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Transcript tahrirlash
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transcript', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: transcript,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Transcript matnini kiriting...',
                  ),
                  maxLines: 5,
                  onChanged: (val) {
                    final newData = Map<String, dynamic>.from(_content.data);
                    newData['transcript'] = val;
                    setState(() => _content = _content.copyWith(data: newData));
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Savollar (${questions.length} ta)',
            style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final q = Map<String, dynamic>.from(entry.value);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: q['question'] ?? '',
                    decoration: InputDecoration(
                      labelText: '${index + 1}-savol',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      questions[index]['question'] = val;
                      final newData = Map<String, dynamic>.from(_content.data);
                      newData['questions'] = questions;
                      setState(
                          () => _content = _content.copyWith(data: newData));
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Speaking tahrirlash
  Widget _buildSpeakingEditView(GeneratedContent content) {
    final exercises =
        List<Map<String, dynamic>>.from(content.data['exercises'] ?? []);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ex = Map<String, dynamic>.from(exercises[index]);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              initialValue: ex['prompt'] ?? '',
              decoration: InputDecoration(
                labelText: '${index + 1}-mashq',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (val) {
                exercises[index]['prompt'] = val;
                final newData = Map<String, dynamic>.from(_content.data);
                newData['exercises'] = exercises;
                setState(() => _content = _content.copyWith(data: newData));
              },
            ),
          ),
        );
      },
    );
  }

  /// Ko'rish view (o'zgarmagan)
  Widget _buildContentPreview(GeneratedContent content) {
    switch (content.type) {
      case ContentType.quiz:
        return _buildQuizPreview(content);
      case ContentType.speaking:
        return _buildSpeakingPreview(content);
      case ContentType.listening:
        return _buildListeningPreview(content);
    }
  }

  /// Quiz preview
  Widget _buildQuizPreview(GeneratedContent content) {
    final questions = content.data['questions'] as List? ?? [];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final question = questions[index] as Map<String, dynamic>;
        final questionNum = index + 1;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Savol $questionNum',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    const Spacer(),
                    Text('${question['points'] ?? 10} ball',
                        style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question['question'] ?? '',
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ...((question['options'] as List?) ?? []).map((option) {
                  final isCorrect = option == question['correctAnswer'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isCorrect ? AppColors.success : null,
                              fontWeight: isCorrect ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (question['explanation'] != null) ...[
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          question['explanation'],
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Speaking preview
  Widget _buildSpeakingPreview(GeneratedContent content) {
    final exercises = content.data['exercises'] as List? ?? [];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ex = exercises[index] as Map<String, dynamic>;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}-mashq',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Text(ex['prompt'] ?? '',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w500)),
                if (ex['sampleAnswer'] != null) ...[
                  const Divider(height: 20),
                  Text('Namuna javob:',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(ex['sampleAnswer'],
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Listening preview
  Widget _buildListeningPreview(GeneratedContent content) {
    final transcript = content.data['transcript'] as String? ?? '';
    final questions = content.data['questions'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.article, size: 20),
                    const SizedBox(width: 8),
                    Text('Transcript', style: AppTextStyles.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Text(transcript, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Tushunish savollari (${questions.length} ta)',
            style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value as Map<String, dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${question['question']}',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ...((question['options'] as List?) ?? []).map((option) {
                    final isCorrect = option == question['correctAnswer'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check : Icons.circle_outlined,
                            size: 16,
                            color: isCorrect ? AppColors.success : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(option,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color:
                                        isCorrect ? AppColors.success : null)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // Helper widgets
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          Text(value,
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _getIcon(ContentType type) {
    switch (type) {
      case ContentType.quiz:
        return Icons.quiz;
      case ContentType.speaking:
        return Icons.record_voice_over;
      case ContentType.listening:
        return Icons.headphones;
    }
  }

  String _getCountLabel(ContentType type) {
    switch (type) {
      case ContentType.quiz:
        return 'Savollar';
      case ContentType.speaking:
        return 'Mashqlar';
      case ContentType.listening:
        return 'Savollar';
    }
  }

  String _getCountValue(GeneratedContent content) {
    switch (content.type) {
      case ContentType.quiz:
        return '${content.questionCount ?? 0} ta';
      case ContentType.speaking:
        final exList = content.data['exercises'] as List?;
        return '${exList?.length ?? 0} ta';
      case ContentType.listening:
        // ✅ FIX: questionCount faqat quiz uchun ishlaydi
        // Listening uchun data['questions'] dan o'qiymiz
        final qList = content.data['questions'] as List?;
        return '${qList?.length ?? 0} ta';
    }
  }

  void _handlePublish(BuildContext context) {
    context.push('/teacher/publishing', extra: _content);
  }
}
