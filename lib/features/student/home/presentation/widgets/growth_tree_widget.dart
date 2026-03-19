// lib/features/student/home/presentation/widgets/growth_tree_widget.dart
// So'zona — O'suvchi daraxt widget
// ✅ 4 soniyalik intro animatsiya: urug' → to'liq daraxt
// Streak bosqichlari:
//   0 kun   → 🌱 Urug'
//   1-2 kun → 🌿 Niholcha
//   3-6 kun → 🌳 O'smir
//   7-13 kun→ 🌲 Yosh daraxt
//   14-29   → 🌴 Balog'at
//   30+ kun → 🎄 Ulug' daraxt (gullagan)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/features/student/home/presentation/providers/student_home_provider.dart';

class GrowthTreeWidget extends StatefulWidget {
  final StreakData streak;
  const GrowthTreeWidget({super.key, required this.streak});

  @override
  State<GrowthTreeWidget> createState() => _GrowthTreeWidgetState();
}

class _GrowthTreeWidgetState extends State<GrowthTreeWidget>
    with TickerProviderStateMixin {
  // Intro (4 soniya)
  late AnimationController _introCtrl;
  late Animation<double> _introGrow;
  bool _introFinished = false;

  // Doimiy animatsiyalar
  late AnimationController _swayCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _swayAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _introGrow = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.85, curve: Curves.elasticOut),
    );

    _swayCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _swayAnim = Tween<double>(begin: -0.05, end: 0.05)
        .animate(CurvedAnimation(parent: _swayCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _introCtrl.forward().then((_) {
      if (!mounted) return;
      setState(() => _introFinished = true);
      _swayCtrl.repeat(reverse: true);
      _pulseCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _swayCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int _stage(int s) {
    if (s == 0) return 0;
    if (s <= 2) return 1;
    if (s <= 6) return 2;
    if (s <= 13) return 3;
    if (s <= 29) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.streak.currentStreak;
    final done = widget.streak.todayCompleted;
    final stage = _stage(s);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _sky(stage).withValues(alpha: 0.15),
            _ground(stage).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? AppColors.success.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(children: [
        SizedBox(
          height: 140,
          child: AnimatedBuilder(
            animation: Listenable.merge([_introCtrl, _swayCtrl, _pulseCtrl]),
            builder: (_, __) {
              final grow =
                  _introFinished ? 1.0 : _introGrow.value.clamp(0.0, 1.0);
              final sway = _introFinished ? _swayAnim.value : 0.0;
              final pulse = _introFinished ? _pulseAnim.value : 1.0;
              // opacity = grow bilan birga o'sadi (0.0 → 1.0)
              final opacity = _introFinished ? 1.0 : grow.clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: CustomPaint(
                  painter: _TreePainter(
                    stage: stage,
                    grow: grow,
                    sway: sway,
                    pulse: pulse,
                    done: done,
                  ),
                  size: const Size(double.infinity, 140),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_emoji(stage), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$s kun',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: done ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(_name(stage),
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey(done),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: done
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              done ? "Bugun sug'orildingiz! 💧" : "Daraxtni sug'oring! 💧",
              style: TextStyle(
                fontSize: 11,
                color: done ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  String _emoji(int s) => ['🌱', '🌿', '🌳', '🌲', '🌴', '🎄'][s.clamp(0, 5)];
  String _name(int s) => [
        'Urug\' ekildi',
        "Niholcha o'syapti",
        "O'smir daraxt",
        "Yosh daraxt",
        "Balog'atga yetdi",
        "Ulug' daraxt! 🏆",
      ][s.clamp(0, 5)];

  Color _sky(int s) => [
        const Color(0xFFD1FAE5),
        const Color(0xFFA7F3D0),
        const Color(0xFF6EE7B7),
        const Color(0xFF34D399),
        const Color(0xFF10B981),
        const Color(0xFF059669),
      ][s.clamp(0, 5)];

  Color _ground(int s) => [
        const Color(0xFFFEF3C7),
        const Color(0xFFD9F99D),
        const Color(0xFFBBF7D0),
        const Color(0xFF86EFAC),
        const Color(0xFF4ADE80),
        const Color(0xFF22C55E),
      ][s.clamp(0, 5)];
}

class _TreePainter extends CustomPainter {
  final int stage;
  final double grow; // 0.0→1.0
  final double sway;
  final double pulse;
  final bool done;

  _TreePainter({
    required this.stage,
    required this.grow,
    required this.sway,
    required this.pulse,
    required this.done,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final ground = size.height - 10;

    // Tuproq
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, ground), width: 60 * grow, height: 12 * grow),
      Paint()
        ..color = const Color(0xFF92400E).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );

    if (stage == 0) {
      if (grow > 0.05) _seed(canvas, cx, ground);
      return;
    }

    final ths = [0.0, 25.0, 45.0, 65.0, 80.0, 90.0];
    final th = ths[stage.clamp(0, 5)] * grow;
    _trunk(canvas, cx, ground, th);
    if (th > 5) _leaves(canvas, cx, ground - th);
  }

  void _seed(Canvas canvas, double cx, double g) {
    final h = 20 * grow * pulse;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, g - h / 2), width: 14 * grow, height: h),
      Paint()
        ..color = const Color(0xFF22C55E)
        ..style = PaintingStyle.fill,
    );
    if (grow > 0.2) {
      canvas.drawLine(
        Offset(cx, g),
        Offset(cx, g - 12 * grow),
        Paint()
          ..color = const Color(0xFF92400E)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _trunk(Canvas canvas, double cx, double g, double h) {
    if (h <= 0) return;
    final tws = [0.0, 4.0, 6.0, 8.0, 10.0, 12.0];
    final tw = tws[stage.clamp(0, 5)] * grow;
    final path = Path()
      ..moveTo(cx - tw, g)
      ..quadraticBezierTo(
          cx - tw / 2 + sway * 20, g - h / 2, cx + sway * 10, g - h)
      ..lineTo(cx + tw + sway * 10, g - h)
      ..quadraticBezierTo(cx + tw / 2 + sway * 20, g - h / 2, cx + tw, g)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF92400E)
          ..style = PaintingStyle.fill);
  }

  void _leaves(Canvas canvas, double cx, double top) {
    final colors = done
        ? [
            const Color(0xFF16A34A),
            const Color(0xFF22C55E),
            const Color(0xFF4ADE80)
          ]
        : [
            const Color(0xFF4B7A35),
            const Color(0xFF5A9C42),
            const Color(0xFF6DB855)
          ];

    final cfgs = _configs(cx, top);
    final rng = math.Random(42);

    for (int i = 0; i < cfgs.length; i++) {
      final c = cfgs[i];
      final ox = sway * (rng.nextDouble() * 8 - 4);
      final r = c.r * grow * (i == 0 ? pulse : 1.0);
      if (r <= 0) continue;
      canvas.drawCircle(
        Offset(c.x + ox, c.y),
        r,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.fill,
      );
    }

    if (stage == 5 && grow > 0.8) {
      final rng2 = math.Random(99);
      for (final c in cfgs.take(3)) {
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(c.x + (rng2.nextDouble() - 0.5) * c.r,
                c.y + (rng2.nextDouble() - 0.5) * c.r),
            4 * pulse,
            Paint()
              ..color = Colors.yellow.withValues(alpha: 0.9)
              ..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  List<_LC> _configs(double cx, double top) {
    switch (stage) {
      case 1:
        return [_LC(cx, top, 28)];
      case 2:
        return [
          _LC(cx, top, 36),
          _LC(cx - 15, top + 15, 22),
          _LC(cx + 15, top + 15, 22)
        ];
      case 3:
        return [
          _LC(cx, top - 5, 44),
          _LC(cx - 20, top + 10, 30),
          _LC(cx + 20, top + 10, 30),
          _LC(cx, top + 20, 26)
        ];
      case 4:
        return [
          _LC(cx, top - 8, 52),
          _LC(cx - 25, top + 5, 36),
          _LC(cx + 25, top + 5, 36),
          _LC(cx - 12, top + 22, 30),
          _LC(cx + 12, top + 22, 30)
        ];
      case 5:
        return [
          _LC(cx, top - 12, 58),
          _LC(cx - 28, top + 2, 42),
          _LC(cx + 28, top + 2, 42),
          _LC(cx - 18, top + 20, 34),
          _LC(cx + 18, top + 20, 34),
          _LC(cx, top + 30, 28)
        ];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(_TreePainter o) =>
      o.grow != grow ||
      o.sway != sway ||
      o.pulse != pulse ||
      o.done != done ||
      o.stage != stage;
}

class _LC {
  final double x, y, r;
  const _LC(this.x, this.y, this.r);
}
