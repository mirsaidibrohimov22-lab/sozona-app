// lib/features/leaderboard/presentation/screens/leaderboard_screen.dart
// So'zona — Leaderboard: IELTS kampaniyasi reytingi
//
// DATA: users collection, referralValidCount DESC, limit 50
// MUHIM: Firebase Console da composite index kerak (README ga qarang)
//   Collection: users
//   Fields: referralValidCount DESC, createdAt DESC
//
// NAVIGATSIYA: /leaderboard (RouteNames.leaderboard)

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int referralValidCount;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.referralValidCount,
  });

  factory LeaderboardEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return LeaderboardEntry(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? 'Foydalanuvchi',
      photoUrl: d['photoUrl'] as String?,
      referralValidCount: _toInt(d['referralValidCount']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════

final leaderboardProvider =
    StreamProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('users')
      .orderBy('referralValidCount', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => LeaderboardEntry.fromDoc(doc))
          .where((e) => e.referralValidCount > 0)
          .toList());
});

// ═══════════════════════════════════════════════════════════════
// EKRAN
// ═══════════════════════════════════════════════════════════════

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late Timer _timer;
  Duration _remaining = _timeUntilMonthEnd();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _remaining = _timeUntilMonthEnd());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static Duration _timeUntilMonthEnd() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return endOfMonth.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authNotifierProvider).user?.id ?? '';
    final listAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'IELTS Sovg\'a',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Leaderboard yuklanmadi.\nFirebase Console da index yaratilganligini tekshiring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        data: (entries) => _buildBody(context, entries, currentUid),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<LeaderboardEntry> entries,
    String currentUid,
  ) {
    // Joriy foydalanuvchining o'rni
    final myIndex = entries.indexWhere((e) => e.uid == currentUid);
    final myRank = myIndex == -1 ? null : myIndex + 1;
    final myEntry = myIndex == -1 ? null : entries[myIndex];

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Kampaniya sarlavhasi + countdown ──
              SliverToBoxAdapter(
                child: _CampaignHeader(remaining: _remaining),
              ),

              // ── Top 3 ──
              if (entries.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: _TopThree(
                      entries: entries.take(3).toList(),
                      currentUid: currentUid,
                    ),
                  ),
                ),

              // ── 4-50 ro'yxat ──
              if (entries.length > 3)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final rank = i + 4;
                        final entry = entries[i + 3];
                        final isMe = entry.uid == currentUid;
                        return _ListRow(
                          rank: rank,
                          entry: entry,
                          isMe: isMe,
                        );
                      },
                      childCount: entries.length - 3,
                    ),
                  ),
                ),

              // ── Bo'sh holat ──
              if (entries.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Hali hech kim taklif qilmagan.\nBirinchi bo\'l! 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),

        // ── Joriy foydalanuvchi o'rni (pin) ──
        if (myEntry != null)
          _MyRankBanner(
            rank: myRank!,
            entry: myEntry,
            allEntries: entries,
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KAMPANIYA SARLAVHASI + COUNTDOWN
// ═══════════════════════════════════════════════════════════════

class _CampaignHeader extends StatelessWidget {
  final Duration remaining;
  const _CampaignHeader({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IELTS Sovg\'a — Kim yetaklamoqda?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Eng ko\'p do\'st taklif qilgan g\'olib IELTS imtihon to\'lovini oladi!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Countdown
          Row(
            children: [
              _CountUnit(value: days, label: 'kun'),
              const _CountSep(),
              _CountUnit(value: hours, label: 'soat'),
              const _CountSep(),
              _CountUnit(value: minutes, label: 'daq'),
              const _CountSep(),
              _CountUnit(value: seconds, label: 'son'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountUnit extends StatelessWidget {
  final int value;
  final String label;
  const _CountUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountSep extends StatelessWidget {
  const _CountSep();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP 3
// ═══════════════════════════════════════════════════════════════

class _TopThree extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String currentUid;

  const _TopThree({required this.entries, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    // 1-o'rin markazda, 2-o'rin chap, 3-o'rin o'ng
    final prizes = ['🏆 IELTS', '👑 6 oy', '🎁 3 oy'];
    final heights = [110.0, 90.0, 80.0];
    final colors = [
      const Color(0xFFFFD700), // oltin
      const Color(0xFFC0C0C0), // kumush
      const Color(0xFFCD7F32), // bronza
    ];

    // Tartib: 2, 1, 3
    final order = [
      entries.length > 1 ? 1 : -1,
      0,
      entries.length > 2 ? 2 : -1,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final idx = order[i];
        if (idx == -1) return const Expanded(child: SizedBox());
        final entry = entries[idx];
        final rank = idx + 1;
        final isMe = entry.uid == currentUid;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(10),
            height: heights[idx],
            decoration: BoxDecoration(
              color: colors[idx].withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border.all(
                color: isMe ? AppColors.primary : colors[idx].withOpacity(0.4),
                width: isMe ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rank == 1
                      ? '🥇'
                      : rank == 2
                          ? '🥈'
                          : '🥉',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.displayName.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${entry.referralValidCount} taklif',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prizes[idx],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colors[idx],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 4-50 RO'YXAT SATRI
// ═══════════════════════════════════════════════════════════════

class _ListRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  const _ListRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.08) : AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.textTertiary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage:
                entry.photoUrl != null ? NetworkImage(entry.photoUrl!) : null,
            child: entry.photoUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? '${entry.displayName} (Siz)' : entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                color: isMe ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${entry.referralValidCount}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isMe ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'taklif',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// JORIY FOYDALANUVCHI O'RNI (PIN — pastda)
// ═══════════════════════════════════════════════════════════════

class _MyRankBanner extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final List<LeaderboardEntry> allEntries;

  const _MyRankBanner({
    required this.rank,
    required this.entry,
    required this.allEntries,
  });

  @override
  Widget build(BuildContext context) {
    // Oldingiga o'tish uchun nechta taklif kerak
    final above = rank > 1 ? allEntries[rank - 2] : null;
    final needed =
        above != null ? above.referralValidCount - entry.referralValidCount : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank-o\'rin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sizning o\'rningiz',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${entry.referralValidCount} taklif',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (above != null && needed > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$needed ta taklif kerak ${rank - 1}-o\'ringa o\'tish uchun',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
