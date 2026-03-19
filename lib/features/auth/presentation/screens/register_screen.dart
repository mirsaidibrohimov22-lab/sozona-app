// lib/features/auth/presentation/screens/register_screen.dart
// So'zona — Ro'yxatdan o'tish ekrani
// Yangi hisob yaratish — ism, email, parol

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Ro'yxatdan o'tish ekrani
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Ro'yxatdan o'tish
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authNotifierProvider.notifier).clearFailure();

    await ref.read(authNotifierProvider.notifier).signUpWithEmail(
          displayName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Muvaffaqiyatli ro'yxatdan o'tganda
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.profileIncomplete) {
        context.go(RoutePaths.setupProfile);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ro\'yxatdan o\'tish'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sarlavha
                Text(
                  'Yangi hisob yarating',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.spacingSm),

                Text(
                  'Ma\'lumotlaringizni kiriting',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSizes.spacingXl),

                // Xatolik xabari
                if (authState.failure != null)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingMd),
                    margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      authState.failure!.message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),

                // Ism
                AuthTextField(
                  controller: _nameController,
                  label: 'Ism',
                  hint: 'Ismingizni kiriting',
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ism kiritilishi shart';
                    }
                    if (value.trim().length < 2) {
                      return 'Ism kamida 2 ta belgidan iborat bo\'lishi kerak';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Email
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'email@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email kiritilishi shart';
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Email formati noto\'g\'ri';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Parol
                AuthTextField(
                  controller: _passwordController,
                  label: 'Parol',
                  hint: 'Kamida 8 belgi',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Parol kiritilishi shart';
                    }
                    if (value.length < 8) {
                      return 'Kamida 8 belgi';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'Kamida bitta katta harf kerak';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'Kamida bitta kichik harf kerak';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Kamida bitta raqam kerak';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Parol tasdig'i
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Parolni tasdiqlang',
                  hint: 'Parolni qayta kiriting',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Parolni tasdiqlang';
                    }
                    if (value != _passwordController.text) {
                      return 'Parollar mos kelmadi';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.spacingXl),

                // Ro'yxatdan o'tish tugmasi
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ro\'yxatdan o\'tish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: AppSizes.spacingLg),

                // Kirish havolasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Hisobingiz bormi? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Kirish',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
