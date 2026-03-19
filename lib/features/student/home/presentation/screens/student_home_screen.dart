// lib/features/student/home/presentation/screens/student_home_screen.dart
// So'zona — O'quvchi bosh sahifasi
// ✅ TUZATILDI: AI Motivation banner qo'shildi
// ✅ TUZATILDI: dynamic → UserEntity? (oldingi fix saqlanadi)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/home/presentation/providers/student_home_provider.dart';
import 'package:my_first_app/features/student/home/presentation/widgets/growth_tree_widget.dart';
import 'package:my_first_app/features/student/home/presentation/widgets/quick_actions_widget.dart';
import 'package:my_first_app/features/student/home/presentation/widgets/learning_stats_card.dart';
import 'package:my_first_app/features/student/home/presentation/widgets/level_progress_widget.dart';
import 'package:my_first_app/features/student/home/presentation/widgets/recommended_lesson_card.dart';

/// O'quvchi bosh sahifasi
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(authNotifierProvider).user;
      ref.read(studentHomeProvider.notifier).loadHomeData(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(studentHomeProvider);
    final authState = ref.watch(authNotifierProvider);
    final UserEntity? user = authState.user;

    return Scaffold(
      body: SafeArea(
        child: homeState.isLoading
            ? const AppLoadingWidget()
            : homeState.error != null
                ? AppErrorWidget(
                    message: homeState.error!,
                    onRetry: () => ref
                        .read(studentHomeProvider.notifier)
                        .loadHomeData(user),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(studentHomeProvider.notifier).refresh(),
                    child: _buildContent(context, homeState, user),
                  ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    StudentHomeState homeState,
    UserEntity? user,
  ) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: _buildHeader(context, user),
        ),

        // ── ✅ YANGI: AI Motivation Banner ──
        if (homeState.motivation != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingLg,
              ),
              child: _MotivationBannerWidget(
                message: homeState.motivation!.message,
                onDismiss: () {
                  ref.read(studentHomeProvider.notifier).dismissMotivation();
                },
              ),
            ),
          ),

        if (homeState.motivation != null)
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizes.spacingMd),
          ),

        // ── O'suvchi Daraxt (streak o'rniga) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: GrowthTreeWidget(streak: homeState.streak),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingLg),
        ),

        // ── Daraja progressi ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: LevelProgressWidget(
              level: user?.level.name.toUpperCase() ?? 'A1',
              xp: homeState.totalXp,
              xpForNextLevel: 500,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingXl),
        ),

        // ── Tezkor harakatlar ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mashq qilish',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
                const QuickActionsWidget(),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingXl),
        ),

        // ── O'quv statistikasi ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: LearningStatsCard(
              flashcardsDone: homeState.dailyPlan.flashcardsDone,
              quizzesDone: homeState.dailyPlan.quizzesDone,
              listeningDone: homeState.dailyPlan.listeningDone,
              weakItemsCount: homeState.weakItemsCount,
              speakingDone: homeState.dailyPlan.speakingDone,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingXl),
        ),

        // ── Tavsiya etilgan darslar ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sizga tavsiya',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
                const RecommendedLessonCard(),
              ],
            ),
          ),
        ),

        // Pastki bo'sh joy
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSizes.spacingXxl),
        ),
      ],
    );
  }

  /// Header — salom va bildirishnoma tugmasi
  Widget _buildHeader(BuildContext context, UserEntity? user) {
    final greeting = _getGreeting();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.displayName ?? 'Foydalanuvchi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // ✅ YANGI: Ishlaydigan bildirishnoma tugmasi
          _NotificationBell(userId: user?.id ?? ''),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Xayrli tong! ☀️';
    if (hour < 17) return 'Xayrli kun! 🌤️';
    if (hour < 21) return 'Xayrli kech! 🌙';
    return 'Xayrli tun! 🌃';
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: Motivation Banner Widget (dismiss bilan)
// ═══════════════════════════════════════════════════════════════
class _MotivationBannerWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _MotivationBannerWidget({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_MotivationBannerWidget> createState() =>
      _MotivationBannerWidgetState();
}

class _MotivationBannerWidgetState extends State<_MotivationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🤖', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Coach',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: Bildirishnoma tugmasi — o'qilmagan soni badge bilan
// ═══════════════════════════════════════════════════════════════
class _NotificationBell extends ConsumerWidget {
  final String userId;
  const _NotificationBell({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox(width: 44, height: 44);

    final db = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final unreadCount = snap.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showNotifications(context, ref, userId),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    unreadCount > 0
                        ? Icons.notifications
                        : Icons.notifications_outlined,
                    color: unreadCount > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(userId: userId),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: Bildirishnomalar bottom sheet
// ═══════════════════════════════════════════════════════════════
class _NotificationsSheet extends ConsumerWidget {
  final String userId;
  const _NotificationsSheet({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(firestoreProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Sarlavha
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Bildirishnomalar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _markAllRead(db, userId),
                      child: const Text("Hammasini o'qish"),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Ro'yxat
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: db
                      .collection('notifications')
                      .where('userId', isEqualTo: userId)
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              "Bildirishnomalar yo'q",
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final isRead = data['isRead'] as bool? ?? false;
                        return _NotificationTile(
                          data: data,
                          isRead: isRead,
                          onTap: () => _markRead(db, doc.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markRead(FirebaseFirestore db, String docId) async {
    try {
      await db.collection('notifications').doc(docId).update({'isRead': true});
    } catch (_) {}
  }

  Future<void> _markAllRead(FirebaseFirestore db, String userId) async {
    try {
      final snap = await db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ YANGI: Bitta bildirishnoma tile
// ═══════════════════════════════════════════════════════════════
class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isRead;
  final VoidCallback onTap;
  const _NotificationTile(
      {required this.data, required this.isRead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Bildirishnoma';
    final body = data['body'] as String? ?? data['message'] as String? ?? '';
    final type = data['type'] as String? ?? 'general';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? null : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _typeColor(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(type), color: _typeColor(type), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(_timeAgo(createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'streak':
        return Icons.local_fire_department;
      case 'achievement':
        return Icons.emoji_events;
      case 'lesson':
        return Icons.school;
      case 'reminder':
        return Icons.alarm;
      case 'class':
        return Icons.class_;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'streak':
        return Colors.orange;
      case 'achievement':
        return Colors.amber;
      case 'lesson':
        return AppColors.primary;
      case 'reminder':
        return Colors.blue;
      case 'class':
        return Colors.green;
      case 'quiz':
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
    if (diff.inHours < 24) return '${diff.inHours} soat oldin';
    if (diff.inDays < 7) return '${diff.inDays} kun oldin';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
