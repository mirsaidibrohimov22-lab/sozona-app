// lib/features/premium/presentation/screens/premium_expired_screen.dart
// So'zona — Loss Aversion ekrani
// Premium tugaganda foydalanuvchi YO'QOTAYOTGANINI ko'rsatadi.
// FAQAT YANGI FAYL — mavjud hech narsaga tegmaydi.
//
// DATA MANBAI:
//   progress/{uid} → currentStreak, totalXp, badges
//   users/{uid}    → learnedWordsCount (ixtiyoriy)
//
// NAVIGATSIYA:
//   "Davom etish" → /premium (PremiumScreen)
//   "Keyinroq"    → context.pop()

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/providers/firebase_providers.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════

class _LossData {
  final int streak;
  final int totalXp;
  final int badgeCount;
  final int learnedWords;

  const _LossData({
    this.streak = 0,
    this.totalXp = 0,
    this.badgeCount = 0,
    this.learnedWords = 0,
  });
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER — progress + users dan ma'lumot olish
// ═══════════════════════════════════════════════════════════════

final _lossDataProvider =
    FutureProvider.autoDispose.family<_LossData, String>((ref, uid) async {
  final db = ref.watch(firestoreProvider);

  final results = await Future.wait([
    db.collection('progress').doc(uid).get(),
    db.collection('users').doc(uid).get(),
  ]);

  final progressSnap = results[0];
  final userSnap = results[1];

  final progressData = progressSnap.data() ?? {};
  final userData = userSnap.data() ?? {};

  final int streak = _toInt(progressData['currentStreak']);
  final int totalXp = _toInt(progressData['totalXp']);

  // badges — progress yoki users da bo'lishi mumkin
  final rawBadges = progressData['badges'];
  final int badgeCount = rawBadges is List ? rawBadges.length : 0;

  final int learnedWords = _toInt(userData['learnedWordsCount']);

  return _LossData(
    streak: streak,
    totalXp: totalXp,
    badgeCount: badgeCount,
    learnedWords: learnedWords,
  );
});

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

// ═══════════════════════════════════════════════════════════════
// EKRAN
// ═══════════════════════════════════════════════════════════════

class PremiumExpiredScreen extends ConsumerWidget {
  const PremiumExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final uid = user?.id ?? '';

    final lossAsync = ref.watch(_lossDataProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: lossAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildContent(context, const _LossData()),
          data: (data) => _buildContent(context, data),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, _LossData data) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sarlavha ──────────────────────────────────
                const Text(
                  'Premium tugadi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quyida siz qo\'lga kiritgan narsalar — ularga cheklov qo\'yiladi.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // ── "Qo'lga kiritgan narsalar" bloki ──────────
                _SectionLabel(text: 'Siz qo\'lga kiritgan narsalar'),
                const SizedBox(height: 12),

                _StatRow(
                  emoji: '🔥',
                  label: '${data.streak} kunlik streak',
                  sublabel: 'Yo\'qolish xavfida!',
                  value: data.streak,
                  maxValue: 30,
                  color: AppColors.accent,
                  show: true,
                ),
                const SizedBox(height: 10),

                _StatRow(
                  emoji: '⭐',
                  label: '${data.totalXp} XP yig\'ilgan',
                  sublabel: 'Tajriba ball',
                  value: data.totalXp,
                  maxValue: 1000,
                  color: AppColors.warning,
                  show: true,
                ),
                const SizedBox(height: 10),

                if (data.learnedWords > 0) ...[
                  _StatRow(
                    emoji: '📚',
                    label: '${data.learnedWords} ta so\'z o\'rgangan',
                    sublabel: 'Lug\'at boyligi',
                    value: data.learnedWords,
                    maxValue: 500,
                    color: AppColors.secondary,
                    show: true,
                  ),
                  const SizedBox(height: 10),
                ],

                _StatRow(
                  emoji: '🏅',
                  label: '${data.badgeCount} ta badge',
                  sublabel: 'Yutuqlar',
                  value: data.badgeCount,
                  maxValue: 10,
                  color: AppColors.primary,
                  show: true,
                ),

                const SizedBox(height: 28),

                // ── Ogohlantirish banneri ──────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Premium bo\'lmasa bularning hammasiga cheklov qo\'yiladi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Nima yo'qoladi ─────────────────────────────
                _LossItem(text: 'AI murabbiy va premium darslar yopiladi'),
                _LossItem(text: 'Streak mukofotlari to\'xtatiladi'),
                _LossItem(text: 'Ilg\'or mashqlar cheklangan bo\'ladi'),
              ],
            ),
          ),
        ),

        // ── Pastdagi tugmalar ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              // Asosiy CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => context.pushNamed(RouteNames.premium),
                  child: const Text(
                    'Davom etish — \$4.99/oy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Keyinroq
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed(RouteNames.studentHome);
                    }
                  },
                  child: const Text(
                    'Keyinroq',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// YORDAMCHI WIDGETLAR
// ═══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        textBaseline: TextBaseline.alphabetic,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final int value;
  final int maxValue;
  final Color color;
  final bool show;

  const _StatRow({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final progress = maxValue > 0
        ? (value / maxValue).clamp(0.0, 1.0)
        : (value > 0 ? 1.0 : 0.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LossItem extends StatelessWidget {
  final String text;
  const _LossItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
