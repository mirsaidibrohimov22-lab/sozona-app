// lib/features/teacher/publishing/presentation/screens/publishing_screen.dart
// ✅ FIX: Sinf ro'yxatini ko'rsatadi, teacher tanlaydi va Firestore'ga yuboradi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/content_generator/domain/entities/generated_content.dart';

class PublishingScreen extends ConsumerStatefulWidget {
  final GeneratedContent content;

  const PublishingScreen({
    super.key,
    required this.content,
  });

  @override
  ConsumerState<PublishingScreen> createState() => _PublishingScreenState();
}

class _PublishingScreenState extends ConsumerState<PublishingScreen> {
  final List<String> _selectedClassIds = [];
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinfga Yuborish'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kontent haqida ma'lumot
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(widget.content.type),
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content.topic,
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        '${widget.content.type.displayName} • ${widget.content.language.toUpperCase()} ${widget.content.level}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Qaysi sinflarga yuborish?',
              style: AppTextStyles.titleMedium,
            ),
          ),
          const SizedBox(height: 8),

          // Sinflar ro'yxati
          Expanded(
            child: classesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 8),
                    Text('Sinflarni yuklashda xato',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => ref.invalidate(teacherClassesProvider),
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
              data: (classes) {
                if (classes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.class_outlined,
                            size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'Sinflar topilmadi',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Avval sinf yarating',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    final isSelected = _selectedClassIds.contains(cls.id);

                    return _ClassTile(
                      schoolClass: cls,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedClassIds.remove(cls.id);
                          } else {
                            _selectedClassIds.add(cls.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Yuborish tugmasi
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedClassIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${_selectedClassIds.length} ta sinf tanlandi',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _selectedClassIds.isEmpty || _isPublishing
                        ? null
                        : _handlePublish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isPublishing ? 'Yuborilmoqda...' : 'Yuborish',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  Future<void> _handlePublish() async {
    setState(() => _isPublishing = true);

    try {
      final firestore = ref.read(firestoreProvider);
      final user = ref.read(authNotifierProvider).user;
      if (user == null) throw Exception('Tizimga kirish kerak');

      final batch = firestore.batch();
      final now = Timestamp.now();

      // Har bir tanlangan sinfga kontent yuborish
      for (final classId in _selectedClassIds) {
        // 1. class_content subcollection ga kontent yozish
        final contentRef = firestore
            .collection('classes')
            .doc(classId)
            .collection('content')
            .doc();

        batch.set(contentRef, {
          'id': contentRef.id,
          'type': widget.content.type.toFirestore(),
          'topic': widget.content.topic,
          'language': widget.content.language,
          'level': widget.content.level,
          'data': widget.content.data,
          'aiModel': widget.content.aiModel,
          'createdBy': user.id,
          'createdAt': now,
          'publishedAt': now,
          'isActive': true,
        });

        // 2. ✅ YANGI: Root content collection ga ham saqlaymiz
        // Student quiz/listening ekrani shu collectiondan o'qiydi
        final rootContentRef =
            firestore.collection('content').doc(contentRef.id);

        batch.set(rootContentRef, {
          'id': contentRef.id,
          'type': widget.content.type.toFirestore(),
          'title': widget.content.topic,
          'topic': widget.content.topic,
          'language': widget.content.language,
          'level': widget.content.level,
          'data': {
            ...widget.content.data,
            'questions': widget.content.data['questions'] ?? [],
          },
          'aiModel': widget.content.aiModel,
          'creatorId': user.id,
          'createdBy': user.id,
          'classId': classId,
          'isPublished': true,
          'generatedByAi': true,
          'attemptCount': 0,
          'averageScore': 0,
          'createdAt': now,
          'publishedAt': now,
        });

        // 3. Sinfning contentCount ni oshirish
        final classRef = firestore.collection('classes').doc(classId);
        batch.update(classRef, {
          'contentCount': FieldValue.increment(1),
          'updatedAt': now,
        });
      }

      await batch.commit();

      // Dashboard ni yangilash
      ref.invalidate(teacherClassesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.content.topic} — ${_selectedClassIds.length} ta sinfga yuborildi!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.go('/teacher/content-generator');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xatolik yuz berdi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getIcon(ContentType type) {
    switch (type) {
      case ContentType.quiz:
        return Icons.quiz;
      case ContentType.speaking:
        return Icons.style;
      case ContentType.listening:
        return Icons.headphones;
    }
  }
}

// ─── Sinf Tile ───────────────────────────────────────

class _ClassTile extends StatelessWidget {
  final SchoolClass schoolClass;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassTile({
    required this.schoolClass,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),

            // Sinf ma'lumotlari
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schoolClass.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  if (schoolClass.description != null &&
                      schoolClass.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      schoolClass.description!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // O'quvchilar soni
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${schoolClass.memberCount} o\'q',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
