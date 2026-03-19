// QO'YISH: lib/features/student/join_class/presentation/screens/join_class_screen.dart
// So'zona — Student sinfga qo'shilish ekrani
// Student join code kiritadi va sinfga qo'shiladi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_button.dart';
import 'package:my_first_app/core/widgets/app_snackbar.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';

/// Student sinfga join code orqali qo'shilish ekrani
class JoinClassScreen extends ConsumerStatefulWidget {
  const JoinClassScreen({super.key});

  @override
  ConsumerState<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends ConsumerState<JoinClassScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Join code bilan sinfga qo'shilish
  Future<void> _joinClass() async {
    final code = _codeController.text.trim().toUpperCase();

    // Validatsiya
    if (code.isEmpty) {
      setState(() => _errorText = 'Kodni kiriting');
      return;
    }
    if (code.length != 6) {
      setState(() => _errorText = 'Kod 6 ta belgi bo\'lishi kerak');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    // Sinfga qo'shilish
    final errorMessage =
        await ref.read(studentClassesProvider.notifier).joinClass(code);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (errorMessage != null) {
      // Xatolik
      setState(() => _errorText = errorMessage);
    } else {
      // Muvaffaqiyat
      AppSnackbar.success(context, 'Sinfga muvaffaqiyatli qo\'shildingiz! 🎉');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sinfga qo\'shilish', style: AppTextStyles.titleLarge),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // ─── Rasm / Icon ───
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Sarlavha ───
            Text(
              'O\'qituvchi kodi bilan\nsinfga qo\'shiling',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'O\'qituvchingizdan 6 harfli kodni so\'rang',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),

            // ─── Kod kiritish maydoni ───
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: AppTextStyles.heading2.copyWith(
                letterSpacing: 8,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: '------',
                hintStyle: AppTextStyles.heading2.copyWith(
                  letterSpacing: 8,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                ),
                errorText: _errorText,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                filled: true,
                fillColor: AppColors.bgPrimary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) => _joinClass(),
            ),
            const SizedBox(height: 32),

            // ─── Qo'shilish tugmasi ───
            AppButton(
              label: 'Sinfga qo\'shilish',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _joinClass,
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 16),

            // ─── Bekor qilish ───
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Bekor qilish',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ─── Izoh ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kod 6 ta harfdan iborat. Katta-kichik harf farq qilmaydi.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
