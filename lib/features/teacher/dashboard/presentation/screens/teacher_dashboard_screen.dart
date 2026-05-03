// lib/features/teacher/dashboard/presentation/screens/teacher_dashboard_screen.dart
// So'zona — O'qituvchi dashboard ekrani
// Sinflar, statistika, tezkor yaratish

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/app_avatar.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/providers/teacher_dashboard_provider.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/widgets/class_overview_card.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/widgets/quick_create_button.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/widgets/teacher_stats_card.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/widgets/student_count_card.dart';
// ✅ YANGI: Faollik grafigi
import 'package:my_first_app/features/teacher/dashboard/presentation/widgets/teacher_activity_chart.dart';

/// O'qituvchi dashboard ekrani
class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState
    extends ConsumerState<TeacherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      ref.read(teacherDashboardProvider.notifier).loadDashboard(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(teacherDashboardProvider);
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      body: SafeArea(
        child: dashState.isLoading
            ? const AppLoadingWidget()
            : dashState.error != null
                ? AppErrorWidget(
                    message: dashState.error!,
                    onRetry: () => ref
                        .read(teacherDashboardProvider.notifier)
                        .loadDashboard(user),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(teacherDashboardProvider.notifier).refresh(),
                    child: _buildContent(context, dashState, user),
                  ),
      ),
      // Tezkor yaratish FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.contentGenerator),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI bilan yaratish'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TeacherDashboardState dashState,
    dynamic user,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(child: _buildHeader(context, user)),

        // ── Statistika kartochkalari ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: StudentCountCard(
                    count: dashState.totalStudents,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Expanded(
                  child: TeacherStatsCard(
                    totalContent: dashState.totalContent,
                    publishedContent: dashState.publishedContent,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingXl),
        ),

        // ── Tezkor yaratish tugmalari ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tezkor yaratish',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
                const QuickCreateButton(),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingXl),
        ),

        // ── Sinflar ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sinflarim',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push(RoutePaths.teacherClasses),
                  child: const Text('Hammasi'),
                ),
              ],
            ),
          ),
        ),

        // Sinflar ro'yxati yoki bo'sh holat
        if (dashState.classes.isEmpty)
          SliverToBoxAdapter(
            child: AppEmptyWidget.noClasses(
              onAction: () => context.push(RoutePaths.teacherClasses),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingLg,
                    vertical: AppSizes.spacingXs,
                  ),
                  child: ClassOverviewCard(
                    classSummary: dashState.classes[index],
                  ),
                );
              },
              childCount: dashState.classes.length,
            ),
          ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingXl),
        ),

        // ── Faollik grafigi va oxirgi faollik ✅ YANGI ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: dashState.classes.isEmpty
                ? const _EmptyActivityChart()
                : TeacherActivityChart(
                    teacherId: user?.id ?? '',
                    classIds: dashState.classes.map((c) => c.id).toList(),
                  ),
          ),
        ),

        // ✅ RESPONSIVE FIX: FAB uchun adaptive pastki bo'sh joy
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
        ),
      ],
    );
  }

  /// Header
  Widget _buildHeader(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xush kelibsiz!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.displayName ?? 'O\'qituvchi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(RoutePaths.notifications),
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textSecondary,
          ),
          GestureDetector(
            onTap: () => context.push(RoutePaths.teacherProfile),
            child: AppAvatar(
              name: user?.displayName ?? 'T',
              imageUrl: user?.photoUrl,
              size: AvatarSize.medium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sinf yo'q bo'lganda grafik placeholder ───
class _EmptyActivityChart extends StatelessWidget {
  const _EmptyActivityChart();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "O'quvchilar faolligi",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Icon(Icons.bar_chart_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              "Sinf qo'shing va o'quvchilar faolligi\nbu yerda ko'rinadi",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
