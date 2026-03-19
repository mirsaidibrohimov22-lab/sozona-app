// lib/features/auth/presentation/screens/setup_profile_screen.dart
// So'zona — Profil sozlash ekrani
// Onboarding: Rol, til, daraja tanlash

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/auth/presentation/widgets/role_selector_widget.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Profil sozlash ekrani — 3 bosqichli
class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Tanlangan qiymatlar
  UserRole _selectedRole = UserRole.student;
  LearningLanguage _selectedLanguage = LearningLanguage.english;
  LanguageLevel _selectedLevel = LanguageLevel.a1;
  AppLanguage _selectedAppLanguage = AppLanguage.uzbek;
  int _dailyGoalMinutes = 15;

  /// Keyingi bosqichga o'tish
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  /// Oldingi bosqichga qaytish
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Profilni saqlash
  Future<void> _saveProfile() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      role: _selectedRole,
      learningLanguage: _selectedLanguage,
      level: _selectedLevel,
      appLanguage: _selectedAppLanguage,
      dailyGoalMinutes: _dailyGoalMinutes,
      isProfileComplete: true,
      updatedAt: DateTime.now(),
    );

    await ref.read(authNotifierProvider.notifier).updateProfile(
          updatedUser: updatedUser,
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Muvaffaqiyatli saqlanganda yo'naltirish
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.authenticated) {
        if (next.user?.isTeacher == true) {
          context.go(RoutePaths.teacherDashboard);
        } else {
          context.go(RoutePaths.studentHome);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indikator
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingLg),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < 2 ? AppSizes.spacingSm : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            : AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Xatolik
            if (authState.failure != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingLg,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    authState.failure!.message,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),

            // Bosqichlar
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildRoleStep(),
                  _buildLanguageStep(),
                  _buildGoalStep(),
                ],
              ),
            ),

            // Tugmalar
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingLg),
              child: Row(
                children: [
                  // Orqaga tugmasi
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                        ),
                        child: const Text('Orqaga'),
                      ),
                    ),

                  if (_currentStep > 0)
                    const SizedBox(width: AppSizes.spacingMd),

                  // Keyingi/Tayyor tugmasi
                  Expanded(
                    flex: _currentStep > 0 ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
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
                          : Text(
                              _currentStep < 2 ? 'Keyingi' : 'Boshlash',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  /// 1-bosqich: Rol tanlash
  Widget _buildRoleStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.spacingLg),
          Text(
            'Siz kimsiz?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            'Rolingizni tanlang',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacingXl),
          RoleSelectorWidget(
            selectedRole: _selectedRole,
            onRoleSelected: (role) {
              setState(() => _selectedRole = role);
            },
          ),
        ],
      ),
    );
  }

  /// 2-bosqich: Til va daraja tanlash
  Widget _buildLanguageStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.spacingLg),

          Text(
            'Qaysi tilni o\'rganasiz?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingXl),

          // O'rganiladigan til
          _buildLanguageOption(
            title: 'Ingliz tili',
            subtitle: 'English',
            icon: '🇬🇧',
            isSelected: _selectedLanguage == LearningLanguage.english,
            onTap: () =>
                setState(() => _selectedLanguage = LearningLanguage.english),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          _buildLanguageOption(
            title: 'Nemis tili',
            subtitle: 'Deutsch',
            icon: '🇩🇪',
            isSelected: _selectedLanguage == LearningLanguage.german,
            onTap: () =>
                setState(() => _selectedLanguage = LearningLanguage.german),
          ),

          const SizedBox(height: AppSizes.spacingXl),

          // Daraja tanlash (faqat o'quvchi uchun)
          if (_selectedRole == UserRole.student) ...[
            Text(
              'Darajangiz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSizes.spacingSm,
              runSpacing: AppSizes.spacingSm,
              children: LanguageLevel.values.map((level) {
                final isSelected = _selectedLevel == level;
                return ChoiceChip(
                  label: Text(level.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedLevel = level);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              _getLevelDescription(_selectedLevel),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppSizes.spacingXl),

          // Ilova tili
          Text(
            'Ilova interfeysi tili',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingMd),

          Row(
            children: [
              Expanded(
                child: _buildAppLanguageOption(
                  title: 'O\'zbekcha',
                  isSelected: _selectedAppLanguage == AppLanguage.uzbek,
                  onTap: () =>
                      setState(() => _selectedAppLanguage = AppLanguage.uzbek),
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: _buildAppLanguageOption(
                  title: 'English',
                  isSelected: _selectedAppLanguage == AppLanguage.english,
                  onTap: () => setState(
                    () => _selectedAppLanguage = AppLanguage.english,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3-bosqich: Kunlik maqsad
  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.spacingLg),

          Text(
            'Kunlik maqsad',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingSm),

          Text(
            'Har kuni qancha vaqt ajratasiz?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingXl * 2),

          // Vaqt tanlash
          ...[5, 10, 15, 20, 30].map((minutes) {
            final isSelected = _dailyGoalMinutes == minutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
              child: InkWell(
                onTap: () => setState(() => _dailyGoalMinutes = minutes),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingLg,
                    vertical: AppSizes.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.bgTertiary,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getGoalIcon(minutes),
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(width: AppSizes.spacingMd),
                      Text(
                        '$minutes daqiqa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getGoalLabel(minutes),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Yordamchi widgetlar ───

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.bgTertiary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: AppSizes.spacingMd),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLanguageOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.bgTertiary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ─── Yordamchi funksiyalar ───

  String _getLevelDescription(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.a1:
        return 'Boshlang\'ich — oddiy so\'z va iboralar';
      case LanguageLevel.a2:
        return 'Asosiy — kundalik mavzularda gaplashish';
      case LanguageLevel.b1:
        return 'O\'rta — mustaqil muloqot qilish';
      case LanguageLevel.b2:
        return 'Yuqori o\'rta — murakkab matnlarni tushunish';
      case LanguageLevel.c1:
        return 'Ilg\'or — erkin gaplashish va yozish';
    }
  }

  IconData _getGoalIcon(int minutes) {
    if (minutes <= 5) return Icons.bolt;
    if (minutes <= 10) return Icons.timer_outlined;
    if (minutes <= 15) return Icons.access_time;
    if (minutes <= 20) return Icons.hourglass_bottom;
    return Icons.military_tech;
  }

  String _getGoalLabel(int minutes) {
    if (minutes <= 5) return 'Tez mashq';
    if (minutes <= 10) return 'Engil';
    if (minutes <= 15) return 'Oddiy';
    if (minutes <= 20) return 'Jiddiy';
    return 'Intensiv';
  }
}
