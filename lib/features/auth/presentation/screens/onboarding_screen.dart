// lib/features/onboarding/presentation/screens/onboarding_screen.dart
// So'zona — Onboarding ekrani
// 3 ta slide — birinchi marta ochilganda ko'rsatiladi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/auth/presentation/widgets/onboarding_page.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Onboarding ekrani — 3 ta slide
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  /// Onboarding sahifalari
  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      icon: Icons.translate,
      title: 'Tilni o\'rganing',
      description:
          'Ingliz yoki nemis tilini AI yordamida oson va qiziqarli usulda o\'rganing',
      color: AppColors.primary,
    ),
    OnboardingPageData(
      icon: Icons.psychology,
      title: 'Aqlli tizim',
      description:
          'AI sizning kuchli va zaif tomonlaringizni aniqlaydi va shaxsiy dastur tuzadi',
      color: AppColors.secondary,
    ),
    OnboardingPageData(
      icon: Icons.emoji_events,
      title: 'Natijaga erishing',
      description:
          'Har kungi mashqlar, streak, XP va boshqa motivatsiya vositalari bilan maqsadga yeting',
      color: AppColors.accent,
    ),
  ];

  /// Keyingi sahifaga o'tish
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  /// Onboardingni o'tkazib yuborish
  Future<void> _completeOnboarding() async {
    // Flagni saqlash
    final localDataSource = ref.read(authLocalDataSourceProvider);
    await localDataSource.setOnboardingComplete();

    if (mounted) {
      context.go(RoutePaths.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // O'tkazib yuborish tugmasi
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingMd),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('O\'tkazib yuborish'),
                ),
              ),
            ),

            // Sahifalar
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(data: _pages[index]);
                },
              ),
            ),

            // Indikatorlar
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.spacingLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Tugma
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingLg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Keyingi' : 'Boshlash',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
