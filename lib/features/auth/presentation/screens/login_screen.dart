// lib/features/auth/presentation/screens/login_screen.dart
// So'zona — Kirish ekrani
// Email yoki Telefon bilan kirish imkoniyati

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Kirish ekrani — Email va Telefon tab
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Email form
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Telefon form
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Email bilan kirish
  Future<void> _signInWithEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    // Xatolikni tozalash
    ref.read(authNotifierProvider.notifier).clearFailure();

    await ref.read(authNotifierProvider.notifier).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  /// Telefon bilan kirish
  Future<void> _signInWithPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    ref.read(authNotifierProvider.notifier).clearFailure();

    final verificationId = await ref
        .read(authNotifierProvider.notifier)
        .signInWithPhone(phoneNumber: _phoneController.text.trim());

    if (verificationId != null && mounted) {
      // OTP ekraniga o'tish
      context.push(
        '/phone-verify',
        extra: {
          'verificationId': verificationId,
          'phoneNumber': _phoneController.text.trim(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Auth holati o'zgarganda yo'naltirish
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.authenticated) {
        if (next.user?.isTeacher == true) {
          context.go(RoutePaths.teacherDashboard);
        } else {
          context.go(RoutePaths.studentHome);
        }
      } else if (next.status == AuthStatus.profileIncomplete) {
        context.go(RoutePaths.setupProfile);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.spacingXl),

              // Sarlavha
              Text(
                'Xush kelibsiz!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.spacingSm),

              Text(
                'Hisobingizga kiring',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.spacingXl),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Email'),
                    Tab(text: 'Telefon'),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.spacingLg),

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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Expanded(
                        child: Text(
                          authState.failure!.message,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Email tab
                    _buildEmailTab(authState),
                    // Telefon tab
                    _buildPhoneTab(authState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Email kirish formasi
  Widget _buildEmailTab(AuthState authState) {
    return Form(
      key: _emailFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email input
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
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Email formati noto\'g\'ri';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Parol input
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
                  return 'Parol kamida 8 belgidan iborat bo\'lishi kerak';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.spacingSm),

            // Parolni unutdim
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(RoutePaths.forgotPassword),
                child: const Text('Parolni unutdingizmi?'),
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Kirish tugmasi
            ElevatedButton(
              onPressed: authState.isLoading ? null : _signInWithEmail,
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
                      'Kirish',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Ro'yxatdan o'tish havolasi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hisobingiz yo\'qmi? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.register),
                  child: const Text(
                    'Ro\'yxatdan o\'ting',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Telefon kirish formasi
  Widget _buildPhoneTab(AuthState authState) {
    return Form(
      key: _phoneFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Telefon raqami input
            AuthTextField(
              controller: _phoneController,
              label: 'Telefon raqami',
              hint: '+998 90 123 45 67',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon raqami kiritilishi shart';
                }
                final phoneRegex = RegExp(r'^\+\d{10,15}$');
                if (!phoneRegex.hasMatch(value.trim())) {
                  return 'Telefon raqami formati: +998901234567';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Telefon bilan kirish tugmasi
            ElevatedButton(
              onPressed: authState.isLoading ? null : _signInWithPhone,
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
                      'Kod yuborish',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Izoh
            const Text(
              'SMS orqali 6 xonali tasdiqlash kodi yuboriladi',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Ro'yxatdan o'tish havolasi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hisobingiz yo\'qmi? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.register),
                  child: const Text(
                    'Ro\'yxatdan o\'ting',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
