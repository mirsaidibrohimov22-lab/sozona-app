import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// So'zona — Muvaffaqiyat animatsiyasi
// Ishlatish misoli:
//
//   Navigator.of(context).push(
//     SozonaSuccessOverlay.route(
//       score: 85,
//       total: 100,
//       module: SozonaModule.quiz,
//       onContinue: () => Navigator.of(context).pop(),
//     ),
//   );
//
//   // Yoki to'g'ridan-to'g'ri widget sifatida:
//   SozonaSuccessScreen(
//     score: 9,
//     total: 10,
//     module: SozonaModule.listening,
//     onContinue: () {},
//   )
// ─────────────────────────────────────────────────────────────────────────────

enum SozonaModule { quiz, listening, speaking, flashcard }

extension SozonaModuleExt on SozonaModule {
  String get title {
    switch (this) {
      case SozonaModule.quiz:
        return 'Quiz';
      case SozonaModule.listening:
        return 'Listening';
      case SozonaModule.speaking:
        return 'Speaking';
      case SozonaModule.flashcard:
        return 'Flashcard';
    }
  }

  IconData get icon {
    switch (this) {
      case SozonaModule.quiz:
        return Icons.quiz_rounded;
      case SozonaModule.listening:
        return Icons.headphones_rounded;
      case SozonaModule.speaking:
        return Icons.mic_rounded;
      case SozonaModule.flashcard:
        return Icons.style_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SozonaModule.quiz:
        return const Color(0xFF6C63FF);
      case SozonaModule.listening:
        return const Color(0xFF00D4AA);
      case SozonaModule.speaking:
        return const Color(0xFFFF9F43);
      case SozonaModule.flashcard:
        return const Color(0xFFFF6584);
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case SozonaModule.quiz:
        return [const Color(0xFF6C63FF), const Color(0xFF9B59B6)];
      case SozonaModule.listening:
        return [const Color(0xFF00D4AA), const Color(0xFF6C63FF)];
      case SozonaModule.speaking:
        return [const Color(0xFFFF9F43), const Color(0xFFFF6584)];
      case SozonaModule.flashcard:
        return [const Color(0xFFFF6584), const Color(0xFFFF9F43)];
    }
  }

  String get congratsText {
    switch (this) {
      case SozonaModule.quiz:
        return "Zo'r natija! 🎯";
      case SozonaModule.listening:
        return 'Ajoyib! Siz yaxshi eshitdingiz! 🎧';
      case SozonaModule.speaking:
        return "Barakalla! Talaffuz zo'r! 🎤";
      case SozonaModule.flashcard:
        return "Mukammal! Kartochkalar o'zlashtirildi! ✨";
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Route — Navigator orqali navigator.push qilish uchun
// ─────────────────────────────────────────────────────────────────────────────
class SozonaSuccessOverlay {
  static PageRoute route({
    required int score,
    required int total,
    required SozonaModule module,
    required VoidCallback onContinue,
    String? subtitle,
    List<_StatItem>? stats,
    VoidCallback? onPremiumCoach, // ✅ FIX: AI Murabbiy tugmasi uchun
  }) {
    return PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => SozonaSuccessScreen(
        score: score,
        total: total,
        module: module,
        onContinue: onContinue,
        subtitle: subtitle,
        stats: stats,
        onPremiumCoach: onPremiumCoach, // ✅
      ),
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Asosiy muvaffaqiyat ekrani
// ─────────────────────────────────────────────────────────────────────────────
class SozonaSuccessScreen extends StatefulWidget {
  final int score;
  final int total;
  final SozonaModule module;
  final VoidCallback onContinue;
  final String? subtitle;
  final List<_StatItem>? stats;
  final VoidCallback? onPremiumCoach; // ✅ FIX: AI Murabbiy tugmasi

  const SozonaSuccessScreen({
    super.key,
    required this.score,
    required this.total,
    required this.module,
    required this.onContinue,
    this.subtitle,
    this.stats,
    this.onPremiumCoach, // ✅
  });

  @override
  State<SozonaSuccessScreen> createState() => _SozonaSuccessScreenState();
}

class _SozonaSuccessScreenState extends State<SozonaSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _cardController;
  late AnimationController _checkController;
  late AnimationController _scoreController;

  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  late Animation<double> _checkProgress;
  late Animation<int> _scoreAnim;
  late Animation<double> _buttonSlide;

  late List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();

    _particles = List.generate(80, (_) => _Particle.random(_rng));

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _cardScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _checkProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );
    _scoreAnim = IntTween(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOut),
    );

    // Ketma-ket animatsiyalar
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _checkController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cardController.dispose();
    _checkController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  double get _percentage => widget.total > 0 ? widget.score / widget.total : 0;

  String get _grade {
    if (_percentage >= 0.9) return 'A+';
    if (_percentage >= 0.8) return 'A';
    if (_percentage >= 0.7) return 'B';
    if (_percentage >= 0.6) return 'C';
    return 'D';
  }

  String get _motivationText {
    if (_percentage >= 0.9) return "Mukammal natija! Siz zo'rsiz! 🌟";
    if (_percentage >= 0.8) return 'Ajoyib! Deyarli mukammal! 🎯';
    if (_percentage >= 0.7) return 'Yaxshi! Davom eting! 💪';
    if (_percentage >= 0.6) return "Zo'r! Ozgina mashq qiling! 📚";
    return 'Tushunmovchilik bor, yana mashq qiling! 🔥';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Stack(
        children: [
          // Confetti qatlami
          AnimatedBuilder(
            animation: _confettiController,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ConfettiPainter(
                particles: _particles,
                progress: _confettiController.value,
                moduleColor: widget.module.color,
              ),
            ),
          ),

          // Markaziy karta
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_cardController, _scoreController]),
              builder: (_, __) => Opacity(
                opacity: _cardOpacity.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: _buildCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final module = widget.module;
    final screenW = MediaQuery.of(context).size.width;

    return Container(
      width: math.min(screenW * 0.88, 360),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: module.color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: module.color.withOpacity(0.25),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modul nomi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: module.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: module.color.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(module.icon, color: module.color, size: 14),
                const SizedBox(width: 6),
                Text(
                  module.title,
                  style: TextStyle(
                    color: module.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Checkmark doirasi
          AnimatedBuilder(
            animation: _checkController,
            builder: (_, __) => _CheckmarkCircle(
              progress: _checkProgress.value,
              color: module.color,
              gradientColors: module.gradientColors,
              size: 88,
            ),
          ),

          const SizedBox(height: 20),

          // Natija foiz
          AnimatedBuilder(
            animation: _scoreController,
            builder: (_, __) => Column(
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_scoreAnim.value}',
                        style: TextStyle(
                          color: module.color,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${widget.total}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_grade  •  ${(_percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Progress bar
          AnimatedBuilder(
            animation: _scoreController,
            builder: (_, __) {
              final animated = _scoreAnim.value / widget.total;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: animated,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(module.color),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Motivatsion matn
          Text(
            _motivationText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          // Qo'shimcha statistika (agar berilgan bo'lsa)
          if (widget.stats != null && widget.stats!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildStats(),
          ],

          const SizedBox(height: 24),

          // Davom etish tugmasi
          AnimatedBuilder(
            animation: _scoreController,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _buttonSlide.value),
              child: Opacity(
                opacity: (1 - _buttonSlide.value / 60).clamp(0.0, 1.0),
                child: Column(
                  children: [
                    _ContinueButton(
                      onTap: widget.onContinue,
                      colors: module.gradientColors,
                    ),
                    // ✅ FIX: Premium AI Murabbiy tugmasi
                    if (widget.onPremiumCoach != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onPremiumCoach,
                          icon: const Icon(
                            Icons.workspace_premium,
                            color: Color(0xFFFFD700),
                            size: 16,
                          ),
                          label: const Text(
                            'AI Murabbiy tahlili',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(
                                color: Color(0xFFFFD700), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: widget.stats!
            .map((s) => _StatWidget(item: s, color: widget.module.color))
            .toList(),
      ),
    );
  }
}

// ─── Stat Item ───────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

// Tashqi ishlatish uchun export
typedef SozonaStatItem = _StatItem;

class _StatWidget extends StatelessWidget {
  final _StatItem item;
  final Color color;

  const _StatWidget({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, color: color.withOpacity(0.8), size: 18),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          item.label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─── Checkmark Circle ────────────────────────────────────────────────────────
class _CheckmarkCircle extends StatelessWidget {
  final double progress;
  final Color color;
  final List<Color> gradientColors;
  final double size;

  const _CheckmarkCircle({
    required this.progress,
    required this.color,
    required this.gradientColors,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CheckmarkPainter(
          progress: progress,
          color: color,
          gradientColors: gradientColors,
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<Color> gradientColors;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Gradient fon doira
    if (progress > 0) {
      final bgPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.25 * progress),
            color.withOpacity(0.05 * progress),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius * progress, bgPaint);
    }

    // Doira chegarasi
    final circlePaint = Paint()
      ..color = color.withOpacity(progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = -math.pi / 2 + progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      circlePaint,
    );

    // Checkmark belgisi
    if (progress > 0.5) {
      final checkProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      _drawCheckmark(canvas, size, center, checkProgress);
    }

    // Glow effekti
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, radius * 0.5 * progress, glowPaint);
  }

  void _drawCheckmark(Canvas canvas, Size size, Offset center, double p) {
    final r = size.width / 2;
    // Checkmark nuqtalari
    final start = Offset(center.dx - r * 0.32, center.dy + r * 0.01);
    final mid = Offset(center.dx - r * 0.06, center.dy + r * 0.28);
    final end = Offset(center.dx + r * 0.38, center.dy - r * 0.22);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(end.dx, end.dy);

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0, pathMetrics.length * p);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) => old.progress != progress;
}

// ─── Continue Button ─────────────────────────────────────────────────────────
class _ContinueButton extends StatefulWidget {
  final VoidCallback onTap;
  final List<Color> colors;

  const _ContinueButton({required this.onTap, required this.colors});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Davom etish',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Confetti Particle ───────────────────────────────────────────────────────
class _Particle {
  final double x; // 0..1
  final double startY;
  final double speedY;
  final double speedX;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final _ParticleShape shape;

  _Particle({
    required this.x,
    required this.startY,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });

  factory _Particle.random(math.Random rng) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D4AA),
      const Color(0xFFFF9F43),
      const Color(0xFFFF6584),
      const Color(0xFFFECA57),
      const Color(0xFF54A0FF),
      const Color(0xFFFF9FF3),
    ];
    final shapes = _ParticleShape.values;

    return _Particle(
      x: rng.nextDouble(),
      startY: -0.05 - rng.nextDouble() * 0.2,
      speedY: 0.25 + rng.nextDouble() * 0.45,
      speedX: (rng.nextDouble() - 0.5) * 0.15,
      size: 4 + rng.nextDouble() * 8,
      color: colors[rng.nextInt(colors.length)],
      rotation: rng.nextDouble() * math.pi * 2,
      rotationSpeed: (rng.nextDouble() - 0.5) * 8,
      shape: shapes[rng.nextInt(shapes.length)],
    );
  }

  double yAt(double t) => startY + speedY * t;
  double xAt(double t, double screenW) => x * screenW + speedX * t * screenW;
  double rotAt(double t) => rotation + rotationSpeed * t;
}

enum _ParticleShape { circle, rect, triangle, star }

// ─── Confetti Painter ────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color moduleColor;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.moduleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = p.yAt(progress) * size.height;
      if (y > size.height + 20) continue;
      final x = p.xAt(progress, size.width);
      final rot = p.rotAt(progress);

      // Yuqori-pastga erib ketish
      final fade = y < 0
          ? 0.0
          : y > size.height * 0.85
              ? (1 - (y - size.height * 0.85) / (size.height * 0.15))
                  .clamp(0.0, 1.0)
              : 1.0;

      final paint = Paint()
        ..color = p.color.withOpacity(fade * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      switch (p.shape) {
        case _ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ParticleShape.rect:
          canvas.drawRect(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.5),
            paint,
          );
          break;
        case _ParticleShape.triangle:
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 2, p.size / 2)
            ..lineTo(-p.size / 2, p.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case _ParticleShape.star:
          _drawStar(canvas, p.size / 2, paint);
          break;
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double r, Paint paint) {
    final path = Path();
    final innerR = r * 0.4;
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = ((i * 72 + 36) - 90) * math.pi / 180;
      if (i == 0) {
        path.moveTo(r * math.cos(outerAngle), r * math.sin(outerAngle));
      } else {
        path.lineTo(r * math.cos(outerAngle), r * math.sin(outerAngle));
      }
      path.lineTo(innerR * math.cos(innerAngle), innerR * math.sin(innerAngle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Qulay yordam funksiyalari — to'g'ridan-to'g'ri chaqirish uchun
// ─────────────────────────────────────────────────────────────────────────────

/// Quiz tugaganda muvaffaqiyat ekranini ko'rsatish
void showQuizSuccess(
  BuildContext context, {
  required int correctAnswers,
  required int totalQuestions,
  required VoidCallback onContinue,
}) {
  Navigator.of(context).push(
    SozonaSuccessOverlay.route(
      score: correctAnswers,
      total: totalQuestions,
      module: SozonaModule.quiz,
      onContinue: onContinue,
      stats: [
        _StatItem(
          label: "To'g'ri",
          value: '$correctAnswers',
          icon: Icons.check_circle_rounded,
        ),
        _StatItem(
          label: "Noto'g'ri",
          value: '${totalQuestions - correctAnswers}',
          icon: Icons.cancel_rounded,
        ),
        _StatItem(
          label: 'Foiz',
          value: '${(correctAnswers / totalQuestions * 100).toInt()}%',
          icon: Icons.percent_rounded,
        ),
      ],
    ),
  );
}

/// Listening tugaganda muvaffaqiyat ekranini ko'rsatish
void showListeningSuccess(
  BuildContext context, {
  required int score,
  required int total,
  required VoidCallback onContinue,
  VoidCallback? onPremiumCoach, // ✅ FIX: AI Murabbiy tugmasi
}) {
  Navigator.of(context).push(
    SozonaSuccessOverlay.route(
      score: score,
      total: total,
      module: SozonaModule.listening,
      onContinue: onContinue,
      onPremiumCoach: onPremiumCoach, // ✅
    ),
  );
}

/// Speaking tugaganda muvaffaqiyat ekranini ko'rsatish
void showSpeakingSuccess(
  BuildContext context, {
  required int pronunciationScore,
  required VoidCallback onContinue,
  String? feedback,
}) {
  Navigator.of(context).push(
    SozonaSuccessOverlay.route(
      score: pronunciationScore,
      total: 100,
      module: SozonaModule.speaking,
      onContinue: onContinue,
      subtitle: feedback,
      stats: [
        _StatItem(
          label: 'Ball',
          value: '$pronunciationScore',
          icon: Icons.mic_rounded,
        ),
        _StatItem(
          label: 'Daraja',
          value: pronunciationScore >= 80
              ? "A'lo"
              : pronunciationScore >= 60
                  ? 'Yaxshi'
                  : "O'rta",
          icon: Icons.bar_chart_rounded,
        ),
      ],
    ),
  );
}
