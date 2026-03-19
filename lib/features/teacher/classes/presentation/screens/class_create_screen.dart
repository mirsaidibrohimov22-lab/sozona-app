// lib/features/teacher/classes/presentation/screens/class_create_screen.dart
// So'zona — Yangi sinf yaratish ekrani
// ✅ 1-KUN FIX (F): Scaffold bilan o'raldi — GoRoute full-screen ochganda
//    overflow bo'lmaydi (oldingi 127px overflow tuzatildi)
// ✅ 1-KUN FIX: resizeToAvoidBottomInset: true — keyboard chiqsa layout moslashadi
// ✅ 1-KUN FIX: SafeArea qo'shildi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/core/widgets/app_snackbar.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';

class ClassCreateScreen extends ConsumerStatefulWidget {
  const ClassCreateScreen({super.key});

  @override
  ConsumerState<ClassCreateScreen> createState() => _ClassCreateScreenState();
}

class _ClassCreateScreenState extends ConsumerState<ClassCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedLanguage = 'en';
  String _selectedLevel = 'A1';
  bool _isLoading = false;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
  static const _languages = [
    {'code': 'en', 'name': 'Inglizcha 🇬🇧'},
    {'code': 'de', 'name': 'Nemischa 🇩🇪'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(teacherClassesProvider.notifier).createClass(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            language: _selectedLanguage,
            level: _selectedLevel,
          );
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(context, 'Sinf muvaffaqiyatli yaratildi! 🎉');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1-KUN FIX (F): Scaffold bilan o'rash — GoRoute full-screen ochganda
    // keyboard chiqqanda overflow bo'lmaydi
    return Scaffold(
      // ✅ keyboard chiqqanda body o'lchami moslashadi
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Yangi sinf yaratish'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sarlavha ikonka
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.class_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Yangi sinf yaratish',
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sinf nomi
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sinf nomi *',
                    hintText: 'Masalan: English A2 Group',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Sinf nomini kiriting';
                    }
                    if (value.trim().length < 3) {
                      return "Nom kamida 3 ta belgi bo'lsin";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tavsif
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Tavsif (ixtiyoriy)',
                    hintText: 'Sinf haqida qisqacha...',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                // Til tanlash
                Text("O'rganish tili", style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Row(
                  children: _languages.map((lang) {
                    final isSelected = _selectedLanguage == lang['code'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _selectedLanguage = lang['code']!,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              lang['name']!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Daraja tanlash
                Text('Daraja (CEFR)', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _levels.map((lvl) {
                    final isSelected = _selectedLevel == lvl;
                    return ChoiceChip(
                      label: Text(lvl),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedLevel = lvl),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Yaratish tugmasi
                AppButton(
                  label: 'Sinf yaratish',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _createClass,
                  icon: Icons.check_rounded,
                ),

                // Keyboard uchun pastdan bo'sh joy
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
