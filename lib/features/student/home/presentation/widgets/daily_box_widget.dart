// lib/features/student/home/presentation/widgets/daily_box_widget.dart
// So'zona — Kundalik sirpriz quti widget
//
// ISHLASH TARTIBI:
//   1. initState da canOpenToday tekshiriladi
//   2. Ochish tugmasiga bosganda openBox chaqiriladi
//   3. Animatsiya: quti scale 0→1 bilan "portlaydi"
//   4. Dialog: mukofot ko'rsatiladi
//
// FOYDALANISH:
//   DailyBoxWidget(uid: user.id)
//   (student_home_screen.dart ichida)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_first_app/core/services/daily_box_service.dart';
import 'package:my_first_app/core/theme/app_colors.dart';

class DailyBoxWidget extends ConsumerStatefulWidget {
  final String uid;

  const DailyBoxWidget({super.key, required this.uid});

  @override
  ConsumerState<DailyBoxWidget> createState() => _DailyBoxWidgetState();
}

class _DailyBoxWidgetState extends ConsumerState<DailyBoxWidget>
    with SingleTickerProviderStateMixin {
  // ── Holat ──────────────────────────────────────────────────
  bool _canOpen = false; // Bugun ocha oladimi
  bool _isLoading = true; // Tekshirish jarayonida
  bool _isOpening = false; // Ochish jarayonida

  // ── Animatsiya ─────────────────────────────────────────────
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Scale animatsiyasi: 0.0 → 1.0 (elastik)
    // value: 1.0 — dastlab emoji to'liq ko'rinadi (0.0 bo'lsa — ko'rinmaydi)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _checkCanOpen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Bugun ochish mumkinmi — initState dan chaqiriladi
  // ─────────────────────────────────────────────────────────────
  Future<void> _checkCanOpen() async {
    final svc = ref.read(dailyBoxServiceProvider);
    final can = await svc.canOpenToday(widget.uid);
    if (!mounted) return;
    setState(() {
      _canOpen = can;
      _isLoading = false;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Qutini ochish
  // ─────────────────────────────────────────────────────────────
  Future<void> _openBox() async {
    if (_isOpening || !_canOpen) return;
    setState(() => _isOpening = true);

    final svc = ref.read(dailyBoxServiceProvider);
    final reward = await svc.openBox(widget.uid);
    if (!mounted) return;

    // Animatsiyani boshlash
    _controller.reset();
    _controller.forward();

    setState(() {
      _canOpen = false; // Bugun yana ocholmaydi
      _isOpening = false;
    });

    // Dialog ko'rsatish (animatsiya tugashini kutmaymiz — birgalikda ishlaydi)
    _showRewardDialog(reward);
  }

  // ─────────────────────────────────────────────────────────────
  // Mukofot dialogi
  // ─────────────────────────────────────────────────────────────
  void _showRewardDialog(DailyReward reward) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _RewardDialog(reward: reward),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Tekshirish davom etsa — hech narsa ko'rsatmaslik
    if (_isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _canOpen
              ? AppColors.warning.withOpacity(0.6)
              : Theme.of(context).dividerColor,
        ),
        gradient: _canOpen
            ? LinearGradient(
                colors: [
                  AppColors.warning.withOpacity(0.08),
                  AppColors.accent.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Row(
        children: [
          // ── Quti emoji (animatsiyali) ──
          ScaleTransition(
            scale: _scaleAnim,
            child: Text(
              _canOpen ? '🎁' : '📦',
              style: const TextStyle(fontSize: 36),
            ),
          ),

          const SizedBox(width: 14),

          // ── Matn ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugungi sovg\'angiz',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _canOpen
                      ? 'Qutini oching — nimalar bor?'
                      : 'Ertaga yangi sovg\'a kutmoqda',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Tugma ─────────────────────────────────────────────
          _canOpen
              ? FilledButton(
                  onPressed: _isOpening ? null : _openBox,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isOpening
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Ochish',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Ertaga',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MUKOFOT DIALOGI — alohida widget
// ═══════════════════════════════════════════════════════════════

class _RewardDialog extends StatelessWidget {
  final DailyReward reward;

  const _RewardDialog({required this.reward});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Katta emoji ──
          Text(
            reward.emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),

          // ── Xabar ──
          Text(
            reward.message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // ── Kichik izoh ──
          Text(
            _subText(reward.type),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),

          // ── Yopish tugmasi ──
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Rahmat!'),
            ),
          ),
        ],
      ),
    );
  }

  // Har bir mukofot uchun qo'shimcha izoh
  String _subText(DailyRewardType type) {
    return switch (type) {
      DailyRewardType.xp50 => 'XP hisobingizga qo\'shildi',
      DailyRewardType.xp100 => 'XP hisobingizga qo\'shildi',
      DailyRewardType.premiumDay => 'Premium muddatingiz 1 kunga uzaydi',
      DailyRewardType.badge => 'Profilingizga qo\'shildi',
      DailyRewardType.nothing =>
        'Har kuni kirgan foydalanuvchilarga katta mukofot!',
    };
  }
}
