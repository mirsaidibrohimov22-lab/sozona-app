// lib/features/student/ai_tutor/presentation/screens/ai_tutor_screen.dart
// So'zona — AI Murabbiy asosiy sahifasi
// ✅ Kitoblar bo'limi + overflow fix

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/ai_tutor/presentation/providers/ai_tutor_provider.dart';
import 'package:my_first_app/features/student/ai_tutor/presentation/widgets/recommendation_card.dart';
import 'package:my_first_app/features/student/ai_tutor/presentation/widgets/weekly_stats_chart.dart';

// ── Daraja ma'lumotlari ───────────────────────────────────────
const _levelData = {
  'a1': _LevelData('🌱', Color(0xFF22C55E), 'A1', "Boshlang'ich"),
  'a2': _LevelData('🌿', Color(0xFF16A34A), 'A2', 'Asosiy'),
  'b1': _LevelData('⭐', Color(0xFF3B82F6), 'B1', "O'rta"),
  'b2': _LevelData('🔥', Color(0xFF8B5CF6), 'B2', "Yuqori o'rta"),
  'c1': _LevelData('👑', Color(0xFFFFD700), 'C1', "Ilg'or"),
};

class _LevelData {
  final String emoji;
  final Color color;
  final String label;
  final String title;
  const _LevelData(this.emoji, this.color, this.label, this.title);
}

// ═══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  @override
  Widget build(BuildContext context) {
    final tutorState = ref.watch(aiTutorProvider);
    final user = ref.watch(authNotifierProvider).user;
    final userLevel = user?.level.name.toLowerCase() ?? 'a1';
    final langName = user?.learningLanguage.name ?? 'english';
    final langLabel =
        langName == 'english' ? 'Ingliz tili 🇬🇧' : 'Nemis tili 🇩🇪';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(aiTutorProvider.notifier).loadAll(),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.school_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Murabbiy',
                                      style: AppTextStyles.titleLarge
                                          .copyWith(color: Colors.white),
                                    ),
                                    Text(
                                      user != null
                                          ? '${user.displayName} · ${user.level.name.toUpperCase()}'
                                          : "So'zona",
                                      style: AppTextStyles.bodySmall
                                          .copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              if (tutorState.mistakeCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${tutorState.mistakeCount} xato',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tavsiyalar
                    _SectionHeader(
                      title: 'Bugun nima qilasiz?',
                      subtitle: 'Sizga maxsus tanlab olindi',
                      onRefresh: () => ref
                          .read(aiTutorProvider.notifier)
                          .loadRecommendations(),
                    ),
                    const SizedBox(height: AppSizes.spacingMd),

                    if (tutorState.isLoading)
                      const AppLoadingWidget()
                    else if (tutorState.recommendations.isEmpty)
                      _EmptyRecommendations(
                        onTap: () => context.push(RoutePaths.quiz),
                      )
                    else
                      ...tutorState.recommendations.map(
                        (rec) => RecommendationCard(
                          rec: rec,
                          onTap: () => _openContent(context, rec, user),
                        ),
                      ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // ── Kitoblar ──
                    _SectionHeader(
                      title: '📚 Premium Kitoblar',
                      subtitle: '$langLabel · A1 dan C1 gacha',
                    ),
                    const SizedBox(height: AppSizes.spacingMd),
                    _BooksSection(
                      userLevel: userLevel,
                      language: langName,
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // ── AI Chat ──
                    _ChatBanner(
                      onTap: () => context.push(RoutePaths.aiChat),
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // ── Haftalik statistika ──
                    _SectionHeader(
                      title: 'Bu hafta',
                      subtitle: tutorState.weeklyStats.weekId.isNotEmpty
                          ? tutorState.weeklyStats.weekId
                          : 'Statistika',
                    ),
                    const SizedBox(height: AppSizes.spacingMd),

                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingLg),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: tutorState.isLoadingStats
                          ? const SizedBox(
                              height: 100,
                              child: AppLoadingWidget(),
                            )
                          : WeeklyStatsChart(stats: tutorState.weeklyStats),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openContent(
      BuildContext context, TutorRecommendation rec, UserEntity? user) {
    switch (rec.type) {
      case 'quiz':
        context.push(RoutePaths.quizDetailPath(rec.contentId));
      case 'flashcard':
        context.push(RoutePaths.flashcardFolderPath(rec.contentId));
      case 'listening':
        context.push(RoutePaths.listeningDetailPath(rec.contentId));
      case 'speaking':
        context.push(RoutePaths.speaking);
      default:
        context.push(RoutePaths.quiz);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// KITOBLAR BO'LIMI — overflow to'g'irlangan
// ═══════════════════════════════════════════════════════════════

class _BooksSection extends StatelessWidget {
  final String userLevel;
  final String language;

  const _BooksSection({
    required this.userLevel,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final levels = ['a1', 'a2', 'b1', 'b2', 'c1'];

    return Column(
      children: [
        // ── Daraja kartalari (gorizontal scroll) ──
        SizedBox(
          // ✅ FIX: 110 → 130 — "Siz" badge uchun joy
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: levels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final level = levels[i];
              final data = _levelData[level]!;
              final isCurrent = level == userLevel;

              return GestureDetector(
                onTap: () => context.push(RoutePaths.bookReaderPath(level)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  // ✅ FIX: width 100, padding 10 — elementlar sig'adi
                  width: 100,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent
                          ? data.color.withOpacity(0.8)
                          : data.color.withOpacity(0.25),
                      width: isCurrent ? 2 : 1,
                    ),
                    color: isCurrent
                        ? data.color.withOpacity(0.1)
                        : data.color.withOpacity(0.04),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Emoji
                      Text(
                        data.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),

                      // Daraja (A1, B2...)
                      Text(
                        data.label,
                        style: TextStyle(
                          color: data.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      // Sarlavha (Boshlang'ich...)
                      Text(
                        data.title,
                        style: TextStyle(
                          color: data.color.withOpacity(0.7),
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ✅ FIX: "Siz" badge — FittedBox ichida
                      if (isCurrent) ...[
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: data.color.withOpacity(0.2),
                            ),
                            child: Text(
                              'Sizning daraja',
                              style: TextStyle(
                                color: data.color,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ── Barcha kitoblar tugmasi ──
        GestureDetector(
          onTap: () => context.push(RoutePaths.books),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              color: AppColors.primary.withOpacity(0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Barcha kitoblarni ko'rish",
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    color: AppColors.primary, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KICHIK WIDGETLAR
// ═══════════════════════════════════════════════════════════════

class _EmptyRecommendations extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyRecommendations({required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: AppColors.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Birinchi darsni tugatgach\nAI murabbiy tavsiyalar beradi!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Birinchi darsni boshlash'),
            ),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading4
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Yangilash',
              iconSize: 20,
            ),
        ],
      );
}

class _ChatBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.secondary.withOpacity(0.15),
                AppColors.primary.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.secondaryDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI bilan suhbatlashing',
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "Savol bering, grammatika so'rang",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryDark,
              ),
            ],
          ),
        ),
      );
}
