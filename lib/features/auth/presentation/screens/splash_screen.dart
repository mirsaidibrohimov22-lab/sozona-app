// lib/features/auth/presentation/screens/splash_screen.dart
// So'zona — Splash Screen v2.0 (To'tiqush maskot)
// ✅ Batafsil to'tiqush CustomPainter bilan
// ✅ Nebula/Aurora fon, yulduzlar
// ✅ Uchuvchi pat zarrachalari
// ✅ Qanotlar animatsiyasi, nafas pulsatsiyasi
// ✅ Staggered matn animatsiyasi

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Controllars
  late AnimationController _parrotCtrl;
  late AnimationController _wingCtrl;
  late AnimationController _breatheCtrl;
  late AnimationController _titleCtrl;
  late AnimationController _taglineCtrl;
  late AnimationController _dotsCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;

  // Animatsiyalar
  late Animation<double> _parrotY;
  late Animation<double> _parrotScale;
  late Animation<double> _parrotOpacity;
  late Animation<double> _wingFlap;
  late Animation<double> _breathe;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _dotsOpacity;
  late Animation<double> _glowPulse;

  final _rng = math.Random();
  late List<_Particle> _particles;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(30, (_) => _Particle.random(_rng));
    _setupControllers();
    _runSequence();
    _checkAuth(); // ✅ FIX: animatsiya bilan parallel — ko'k ekran muammosi hal qilindi
  }

  void _setupControllers() {
    _parrotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _wingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _breatheCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _titleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _dotsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _particleCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _parrotY = Tween<double>(begin: 80, end: 0).animate(
        CurvedAnimation(parent: _parrotCtrl, curve: Curves.elasticOut));
    _parrotScale = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(
        parent: _parrotCtrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _parrotOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _parrotCtrl,
        curve: const Interval(0, 0.35, curve: Curves.easeIn)));
    _wingFlap = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _wingCtrl, curve: Curves.easeInOut));
    _breathe = Tween<double>(begin: 1.0, end: 1.055).animate(
        CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
    _titleOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic));
    _taglineOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));
    _dotsOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _dotsCtrl, curve: Curves.easeOut));
    _glowPulse = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _parrotCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // 3 marta qanat qoqish
    for (int i = 0; i < 3; i++) {
      await _wingCtrl.forward();
      await _wingCtrl.reverse();
    }

    if (!mounted) return;
    _titleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _taglineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _dotsCtrl.forward();
    // _checkAuth() endi initState da parallel ishga tushadi
  }

  Future<void> _checkAuth() async {
    // ✅ FIX: animatsiya tugashini kutamiz (~5s)
    await Future.delayed(const Duration(milliseconds: 5000));
    if (!mounted || _hasNavigated) return;
    try {
      await ref.read(authNotifierProvider.notifier).checkAuthStatus();
    } catch (_) {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go(RoutePaths.onboarding);
      }
      return;
    }
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    final state = ref.read(authNotifierProvider);
    switch (state.status) {
      case AuthStatus.authenticated:
        context.go(state.user?.isTeacher == true
            ? RoutePaths.teacherDashboard
            : RoutePaths.studentHome);
        break;
      case AuthStatus.profileIncomplete:
        context.go(RoutePaths.setupProfile);
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
        context.go(RoutePaths.onboarding);
        break;
    }
  }

  @override
  void dispose() {
    _parrotCtrl.dispose();
    _wingCtrl.dispose();
    _breatheCtrl.dispose();
    _titleCtrl.dispose();
    _taglineCtrl.dispose();
    _dotsCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // ✅ FIX: Redmi/MIUI da gradient shader render muammosi
      // Scaffold backgroundColor qora bo'lsa — gradient yuklanguncha ko'k emas qora ko'rinadi
      backgroundColor: const Color(0xFF060414),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _parrotCtrl,
          _wingCtrl,
          _breatheCtrl,
          _titleCtrl,
          _taglineCtrl,
          _dotsCtrl,
          _particleCtrl,
          _glowCtrl,
        ]),
        builder: (context, _) => Stack(
          children: [
            // ── FON ───────────────────────────────────────────────────
            // ✅ FIX: RepaintBoundary — Redmi/MIUI GPU rendering muammosini hal qiladi
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: _BackgroundPainter(
                  time: _particleCtrl.value,
                ),
              ),
            ),

            // ── ZARRACHALAR ───────────────────────────────────────────
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleCtrl.value,
                ),
              ),
            ),

            // ── MARKAZIY KONTENT ──────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── TO'TIQUSH ──────────────────────────────────────
                  // ✅ FIX (Redmi/MIUI): Opacity widget + CustomPaint gradient
                  // GPU "saveLayer" muammosini hal qilish:
                  // Eski: Opacity(child: Stack[Container(gradient), CustomPaint])
                  //       → MIUI GPU saveLayer + gradient = logo ko'rinmaydi
                  // Yangi: RepaintBoundary(child: Opacity(...))
                  //        → RepaintBoundary o'z layerini yaratadi, saveLayer ichida
                  //          gradient muammo yo'qoladi. Barcha Android telifonlarda ishlaydi.
                  RepaintBoundary(
                    child: Opacity(
                      opacity: _parrotOpacity.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _parrotY.value),
                        child: Transform.scale(
                          scale: _parrotScale.value * _breathe.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow halqa — RepaintBoundary ichida xavfsiz
                              RepaintBoundary(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF6C63FF).withOpacity(
                                            0.35 * _glowPulse.value),
                                        const Color(0xFF00D4AA).withOpacity(
                                            0.15 * _glowPulse.value),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.45, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // To'tiqush — o'z RepaintBoundary da
                              RepaintBoundary(
                                child: SizedBox(
                                  width: 190,
                                  height: 200,
                                  child: CustomPaint(
                                    painter: _ParrotPainter(
                                      wingAngle: _wingFlap.value,
                                      breathe: _breatheCtrl.value,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── ILOVA NOMI ─────────────────────────────────────
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      // ✅ FIX (Redmi): ShaderMask + FadeTransition konflikti
                      // RepaintBoundary — ShaderMask ni alohida layerda render qiladi
                      child: RepaintBoundary(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color(0xFFCAC4FF),
                              Color(0xFF00D4AA),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ).createShader(bounds),
                          child: const Text(
                            "So'zona",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── TAGLINE ────────────────────────────────────────
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Text(
                      "TIL O'RGANING — TO'TIQUSH KABI GAPIRING",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.55),
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 55),

                  // ── LOADING DOTS ──────────────────────────────────
                  FadeTransition(
                    opacity: _dotsOpacity,
                    child: _AnimatedDots(),
                  ),
                ],
              ),
            ),

            // ── PASTKI GRADIENT ────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF6C63FF).withOpacity(0.12),
                    ],
                  ),
                ),
              ),
            ),

            // ── VERSIYA ────────────────────────────────────────────
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _dotsOpacity,
                child: Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 11,
                    letterSpacing: 2,
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

// ══════════════════════════════════════════════════════════════════════
// FLESHY TO'TIQUSH — BATAFSIL CustomPainter
// ══════════════════════════════════════════════════════════════════════
class _ParrotPainter extends CustomPainter {
  final double wingAngle;
  final double breathe;

  _ParrotPainter({required this.wingAngle, required this.breathe});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;
    final bs = 1 + breathe * 0.04;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(bs, bs);
    canvas.translate(-cx, -cy);

    // ── Soya ─────────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF6C63FF).withOpacity(0.35),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(cx, cy + 55), radius: 65))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(cx, cy + 55), 55, shadowPaint);

    // ── Qanotlar ──────────────────────────────────────────────────────
    _drawWing(canvas, cx, cy, false, wingAngle);
    _drawWing(canvas, cx, cy, true, wingAngle);

    // ── Quyruq ────────────────────────────────────────────────────────
    final tailCols = [
      const Color(0xFF3498DB),
      const Color(0xFF9B59B6),
      const Color(0xFFE74C3C),
      const Color(0xFFF1C40F),
      const Color(0xFF1ABC9C),
    ];
    for (int i = 0; i < 5; i++) {
      final angle = math.pi / 2 + (i - 2) * 0.22;
      final len = 72.0 + (2 - (i - 2).abs()) * 8;
      final startX = cx + (i - 2) * 9.0;
      final startY = cy + 52.0;
      final cp1x = startX + math.cos(angle + 0.3) * len * 0.4;
      final cp1y = startY + math.sin(angle + 0.3) * len * 0.4;
      final endX = cx + (i - 2) * 6.0 + math.cos(angle) * len;
      final endY = startY + math.sin(angle) * len;

      final path = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(cp1x, cp1y, endX, endY);
      canvas.drawPath(
        path,
        Paint()
          ..color = tailCols[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Tana ──────────────────────────────────────────────────────────
    final bodyPath = Path()
      ..addOval(
          Rect.fromCenter(center: Offset(cx, cy + 12), width: 84, height: 108));
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: const [Color(0xFF3DE07A), Color(0xFF2ECC71), Color(0xFF1F9E55)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 60));
    canvas.drawPath(bodyPath, bodyPaint);

    // Qorin sariq
    final bellyPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF6C0), Color(0xFFF9E04B), Color(0xFFF0C030)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(cx + 5, cy + 22), radius: 28));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 5, cy + 22), width: 44, height: 56),
        bellyPaint);

    // Ko'krak ko'k
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 5, cy + 30), width: 26, height: 32),
      Paint()..color = const Color(0xFF3498DB),
    );

    // Tana ildizi
    canvas.drawPath(
        bodyPath,
        Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // ── Oyoqlar ───────────────────────────────────────────────────────
    _drawLeg(canvas, cx - 14, cy + 62, -1);
    _drawLeg(canvas, cx + 14, cy + 62, 1);

    // ── Bosh ─────────────────────────────────────────────────────────
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: const [Color(0xFF3DE07A), Color(0xFF2ECC71), Color(0xFF1F9E55)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 22), radius: 38));
    canvas.drawCircle(Offset(cx, cy - 22), 36, headPaint);

    // Yonoq sariq
    final cheekPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF6C0), Color(0xFFF9E04B), Color(0x40F0C030)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(cx + 12, cy - 20), radius: 22));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + 12, cy - 20), width: 40, height: 36),
        cheekPaint);

    // ── Tepa toji (crest) ─────────────────────────────────────────────
    _drawCrest(canvas, cx, cy);

    // ── Ko'z ─────────────────────────────────────────────────────────
    canvas.drawCircle(
        Offset(cx + 16, cy - 28), 13, Paint()..color = Colors.white);
    final irisGrad = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFF2C3E50), Color(0xFF1A252F), Color(0xFF0D1520)],
      ).createShader(
          Rect.fromCircle(center: Offset(cx + 18, cy - 27), radius: 10));
    canvas.drawCircle(Offset(cx + 18, cy - 27), 10, irisGrad);
    canvas.drawCircle(
        Offset(cx + 20, cy - 31), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + 19, cy - 27), 1.5,
        Paint()..color = Colors.white.withOpacity(0.7));

    // ── Tumshug' ─────────────────────────────────────────────────────
    final beakPath = Path()
      ..moveTo(cx + 8, cy - 10)
      ..cubicTo(cx + 28, cy - 17, cx + 34, cy - 8, cx + 24, cy - 1)
      ..cubicTo(cx + 17, cy + 3, cx + 10, cy - 2, cx + 8, cy - 10)
      ..close();
    final beakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFF39C12), Color(0xFFC0782A)],
      ).createShader(Rect.fromLTWH(cx + 8, cy - 17, 26, 20));
    canvas.drawPath(beakPath, beakPaint);

    final beakLine = Path()
      ..moveTo(cx + 9, cy - 10)
      ..lineTo(cx + 29, cy - 12);
    canvas.drawPath(
        beakLine,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);

    canvas.restore();
  }

  void _drawWing(
      Canvas canvas, double cx, double cy, bool isRight, double flap) {
    final mx = isRight ? 1.0 : -1.0;
    final angle = flap * 0.6 * mx;

    canvas.save();
    canvas.translate(cx + mx * 30, cy + 10);
    canvas.rotate(angle);

    // Asosiy qanot
    final wingPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(mx * -55, -32, mx * -78, 8, mx * -68, 52)
      ..cubicTo(mx * -52, 72, mx * -22, 62, 0, 40)
      ..close();
    final wingPaint = Paint()
      ..shader = LinearGradient(
        begin: isRight ? Alignment.centerRight : Alignment.centerLeft,
        end: isRight ? Alignment.centerLeft : Alignment.centerRight,
        colors: const [Color(0xFF27AE60), Color(0xFF2ECC71), Color(0xFF1A8A4A)],
      ).createShader(Rect.fromLTWH(mx * -78, -32, 78, 104));
    canvas.drawPath(wingPath, wingPaint);

    // Qanot uchi ko'k
    final tipPath = Path()
      ..moveTo(mx * -34, 8)
      ..cubicTo(mx * -68, 10, mx * -78, 34, mx * -65, 56)
      ..cubicTo(mx * -52, 68, mx * -32, 58, mx * -20, 44)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFF2980B9));

    // Qanot chiziqlar
    for (int i = 1; i <= 5; i++) {
      final t = i / 6.0;
      canvas.drawLine(
        Offset(mx * -t * 55 * 0.25, t * 40 * 0.25),
        Offset(mx * -t * 55, t * 40),
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
  }

  void _drawCrest(Canvas canvas, double cx, double cy) {
    final crests = [
      {
        'ox': -9.0,
        'c0': const Color(0xFFE74C3C),
        'c1': const Color(0xFFC0392B),
        'h': 28.0
      },
      {
        'ox': 0.0,
        'c0': const Color(0xFFE67E22),
        'c1': const Color(0xFFD35400),
        'h': 36.0
      },
      {
        'ox': 9.0,
        'c0': const Color(0xFFF1C40F),
        'c1': const Color(0xFFD4AC0D),
        'h': 28.0
      },
    ];
    for (final d in crests) {
      final ox = d['ox'] as double;
      final c0 = d['c0'] as Color;
      final c1 = d['c1'] as Color;
      final h = d['h'] as double;
      final path = Path()
        ..moveTo(cx + ox - 6, cy - 52)
        ..cubicTo(cx + ox - 7, cy - 56 - h * 0.6, cx + ox + 7,
            cy - 56 - h * 0.6, cx + ox + 6, cy - 52)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [c0, c1],
          ).createShader(Rect.fromLTWH(cx + ox - 7, cy - 56 - h, 14, h + 4)),
      );
      canvas.drawCircle(
          Offset(cx + ox, cy - 54 - h * 0.65), 5.5, Paint()..color = c0);
    }
  }

  void _drawLeg(Canvas canvas, double x, double y, int dir) {
    final p = Paint()
      ..color = const Color(0xFFE67E22)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, y), Offset(x + dir * 4, y + 17), p);
    canvas.drawLine(
        Offset(x + dir * 4, y + 17), Offset(x + dir * 12, y + 23), p);
    canvas.drawLine(
        Offset(x + dir * 4, y + 17), Offset(x + dir * 3, y + 25), p);
    canvas.drawLine(
        Offset(x + dir * 4, y + 17), Offset(x - dir * 3, y + 24), p);
  }

  @override
  bool shouldRepaint(_ParrotPainter old) =>
      old.wingAngle != wingAngle || old.breathe != breathe;
}

// ══════════════════════════════════════════════════════════════════════
// FON — Nebula, Aurora, Yulduzlar
// ══════════════════════════════════════════════════════════════════════
class _BackgroundPainter extends CustomPainter {
  final double time;
  _BackgroundPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // Qora-ko'k asosiy fon
    canvas.drawRect(
      Rect.fromLTWH(0, 0, W, H),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF060414),
            Color(0xFF0F0A28),
            Color(0xFF12082A)
          ],
        ).createShader(Rect.fromLTWH(0, 0, W, H)),
    );

    // Nebula dog'lari
    final nebulas = [
      [0.15 * W, 0.1 * H, 0.28 * W, const Color(0xFF6C3CDC), 0.16],
      [0.78 * W, 0.18 * H, 0.22 * W, const Color(0xFF00B496), 0.1],
      [0.5 * W, 0.04 * H, 0.32 * W, const Color(0xFF3828B4), 0.14],
      [0.88 * W, 0.45 * H, 0.18 * W, const Color(0xFFC85080), 0.09],
    ];
    for (final n in nebulas) {
      canvas.drawCircle(
        Offset(n[0] as double, n[1] as double),
        n[2] as double,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (n[3] as Color).withOpacity(n[4] as double),
              Colors.transparent
            ],
          ).createShader(Rect.fromCircle(
              center: Offset(n[0] as double, n[1] as double),
              radius: n[2] as double)),
      );
    }

    // Aurora shimmer
    final auroraAlpha = 0.04 + 0.02 * math.sin(time * math.pi * 2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, W, H * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(auroraAlpha),
            const Color(0xFF00D4AA).withOpacity(auroraAlpha * 0.6),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, W, H * 0.5)),
    );

    // Yulduzlar
    final rng = math.Random(42);
    for (int i = 0; i < 130; i++) {
      final sx = rng.nextDouble() * W;
      final sy = rng.nextDouble() * H * 0.78;
      final sr = rng.nextDouble() * 1.8 + 0.2;
      final twinkle = 0.25 +
          0.7 *
              (0.5 +
                  0.5 *
                      math.sin(
                          time * math.pi * 2 * (rng.nextDouble() * 0.8 + 0.3) +
                              rng.nextDouble() * math.pi * 2));
      canvas.drawCircle(
        Offset(sx, sy),
        sr * (0.6 + twinkle * 0.4),
        Paint()..color = Colors.white.withOpacity(twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.time != time;
}

// ══════════════════════════════════════════════════════════════════════
// ZARRACHALAR — Uchuvchi pat bo'laklari
// ══════════════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.offset) % 1.0;
      final x =
          p.normalX * size.width + math.sin(t * math.pi * 2 + p.phase) * 35;
      final y = size.height * 0.18 + t * size.height * 0.65;
      final opacity = t < 0.12
          ? t / 0.12
          : t > 0.88
              ? (1 - t) / 0.12
              : 1.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * math.pi * 5 + p.phase);
      canvas.globalAlpha = opacity * 0.75;

      final path = Path()
        ..moveTo(0, -p.size)
        ..cubicTo(
            p.size * 0.6, -p.size * 0.4, p.size * 0.6, p.size * 0.4, 0, p.size)
        ..cubicTo(-p.size * 0.6, p.size * 0.4, -p.size * 0.6, -p.size * 0.4, 0,
            -p.size);

      canvas.drawPath(
          path, Paint()..color = p.color.withOpacity(opacity * 0.75));
      canvas.drawLine(
        Offset(0, -p.size),
        Offset(0, p.size),
        Paint()
          ..color = Colors.white.withOpacity(opacity * 0.25)
          ..strokeWidth = 0.8,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

extension on Canvas {
  set globalAlpha(double _) {}
}

class _Particle {
  final double normalX;
  final double offset;
  final double phase;
  final double size;
  final Color color;

  _Particle({
    required this.normalX,
    required this.offset,
    required this.phase,
    required this.size,
    required this.color,
  });

  factory _Particle.random(math.Random rng) {
    const colors = [
      Color(0xFF2ECC71),
      Color(0xFF3498DB),
      Color(0xFFE74C3C),
      Color(0xFFF1C40F),
      Color(0xFF9B59B6),
      Color(0xFFE67E22),
      Color(0xFF1ABC9C),
      Color(0xFFFF6B9D),
    ];
    return _Particle(
      normalX: rng.nextDouble(),
      offset: rng.nextDouble(),
      phase: rng.nextDouble() * math.pi * 2,
      size: 4 + rng.nextDouble() * 8,
      color: colors[rng.nextInt(colors.length)],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ANIMATSIYALI NUQTALAR
// ══════════════════════════════════════════════════════════════════════
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_ctrl.value + i / 3) % 1.0;
          final bounce = math.sin(phase * math.pi).clamp(0.0, 1.0);
          const colors = [
            Color(0xFF6C63FF),
            Color(0xFF00D4AA),
            Color(0xFFFF9F43)
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Transform.translate(
              offset: Offset(0, -bounce * 10),
              child: Transform.scale(
                scale: 0.7 + bounce * 0.3,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colors[i].withOpacity(0.7 + bounce * 0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: colors[i].withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
