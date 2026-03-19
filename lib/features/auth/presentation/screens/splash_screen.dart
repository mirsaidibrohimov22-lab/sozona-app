// lib/features/auth/presentation/screens/splash_screen.dart
// So'zona — Splash ekrani
// ✅ TUZATILGAN: try-catch, xavfsiz navigatsiya

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // ✅ Splash animatsiyasi uchun kutish
    // Animatsiya parallel ishlaydi - kutish kerak emas
    if (!mounted || _hasNavigated) return;

    // ✅ TUZATISH: try-catch — auth tekshiruvi crash qilsa ham navigatsiya ishlaydi
    try {
      await ref.read(authNotifierProvider.notifier).checkAuthStatus();
    } catch (e) {
      debugPrint('❌ Auth tekshiruv xatosi: $e');
      // Xatolik bo'lsa — onboarding ga yo'naltiramiz
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go(RoutePaths.onboarding);
      }
      return;
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final state = ref.read(authNotifierProvider);

    switch (state.status) {
      case AuthStatus.authenticated:
        context.go(state.user?.isTeacher == true
            ? RoutePaths.teacherDashboard
            : RoutePaths.studentHome);
        break;
      case AuthStatus.profileIncomplete:
        context.go(RoutePaths.setupProfile);
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
        context.go(RoutePaths.onboarding);
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        // ✅ TUZATISH: AnimatedBuilder o'rniga oddiy FadeTransition
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo konteyner
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingLg),

                // Ilova nomi
                const Text(
                  "So'zona",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingSm),

                // Slogan
                Text(
                  "Til o'rganing — oson va qiziqarli",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingXl * 2),

                // Yuklanish indikatori
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8),
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
}
