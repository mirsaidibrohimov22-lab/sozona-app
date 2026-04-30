import 'dart:math' as math;
import 'package:flutter/material.dart';

/// So'zona uchun chiroyli loading animatsiyasi.
/// Ishlatish:
///   SozonaLoadingAnimation(message: "AI javob tayyorlamoqda...")
///   SozonaLoadingAnimation.overlay(context) — ekranning ustida ko'rsatish
class SozonaLoadingAnimation extends StatefulWidget {
  final String? message;
  final LoadingStyle style;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double size;

  const SozonaLoadingAnimation({
    super.key,
    this.message,
    this.style = LoadingStyle.wave,
    this.primaryColor,
    this.secondaryColor,
    this.size = 48,
  });

  /// Ekranning ustiga overlay sifatida ko'rsatish
  static OverlayEntry overlay(
    BuildContext context, {
    String? message,
    LoadingStyle style = LoadingStyle.orbit,
  }) {
    final entry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SozonaLoadingAnimation(
              message: message,
              style: style,
              primaryColor: const Color(0xFF6C63FF),
              secondaryColor: const Color(0xFF00D4AA),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<SozonaLoadingAnimation> createState() => _SozonaLoadingAnimationState();
}

enum LoadingStyle { wave, orbit, pulse, dots }

class _SozonaLoadingAnimationState extends State<SozonaLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _textController;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _textFade = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Color get _primary => widget.primaryColor ?? const Color(0xFF6C63FF);
  Color get _secondary => widget.secondaryColor ?? const Color(0xFF00D4AA);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (_, __) {
              switch (widget.style) {
                case LoadingStyle.wave:
                  return _buildWave();
                case LoadingStyle.orbit:
                  return _buildOrbit();
                case LoadingStyle.pulse:
                  return _buildPulse();
                case LoadingStyle.dots:
                  return _buildDots();
              }
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _textFade,
            child: Text(
              widget.message!,
              style: TextStyle(
                color: _primary.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // === WAVE — 5 ta ustun musiqiy to'lqin kabi ===
  Widget _buildWave() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(5, (i) {
        final delay = i / 5;
        final phase = (_mainController.value + delay) % 1.0;
        final height = (math.sin(phase * 2 * math.pi) * 0.5 + 0.5);
        final barHeight = widget.size * 0.2 + height * widget.size * 0.7;
        final colorT = (i / 4).clamp(0.0, 1.0);
        final color = Color.lerp(_primary, _secondary, colorT)!;
        return AnimatedContainer(
          duration: Duration.zero,
          width: widget.size * 0.1,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.4)],
            ),
            borderRadius: BorderRadius.circular(widget.size * 0.05),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      }),
    );
  }

  // === ORBIT — bitta kichik top katta doira atrofida aylanadi ===
  Widget _buildOrbit() {
    return CustomPaint(
      painter: _OrbitPainter(
        progress: _mainController.value,
        primary: _primary,
        secondary: _secondary,
      ),
    );
  }

  // === PULSE — uch qavat pulslovchi doiralar ===
  Widget _buildPulse() {
    return CustomPaint(
      painter: _PulsePainter(
        progress: _mainController.value,
        primary: _primary,
        secondary: _secondary,
      ),
    );
  }

  // === DOTS — uch nuqta ketma-ket sakraydi ===
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(3, (i) {
        final delay = i / 3;
        final phase = (_mainController.value + delay) % 1.0;
        final bounce = math.sin(phase * math.pi).clamp(0.0, 1.0);
        final offset = bounce * widget.size * 0.25;
        final scale = 0.7 + bounce * 0.3;
        final colorT = (i / 2).clamp(0.0, 1.0);
        final color = Color.lerp(_primary, _secondary, colorT)!;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.size * 0.06),
          child: Transform.translate(
            offset: Offset(0, -offset),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: widget.size * 0.18,
                height: widget.size * 0.18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Orbit Painter ───────────────────────────────────────────────────────────
class _OrbitPainter extends CustomPainter {
  final double progress;
  final Color primary;
  final Color secondary;

  _OrbitPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Markaziy doira
    final corePaint = Paint()
      ..color = primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, corePaint);

    final coreBorderPaint = Paint()
      ..color = primary.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.35, coreBorderPaint);

    // Orbit yo'li
    final orbitPaint = Paint()
      ..color = primary.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, orbitPaint);

    // Aylanuvchi top
    final angle = progress * 2 * math.pi - math.pi / 2;
    final dotX = center.dx + radius * math.cos(angle);
    final dotY = center.dy + radius * math.sin(angle);

    // Iz (trail)
    for (int i = 1; i <= 12; i++) {
      final trailAngle = angle - (i * 0.08);
      final tx = center.dx + radius * math.cos(trailAngle);
      final ty = center.dy + radius * math.sin(trailAngle);
      final opacity = (1 - i / 12) * 0.5;
      final trailPaint = Paint()
        ..color = secondary.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tx, ty), 2.5 * (1 - i / 12), trailPaint);
    }

    // Asosiy top
    final dotPaint = Paint()
      ..color = secondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), size.width * 0.07, dotPaint);

    // Glow
    final glowPaint = Paint()
      ..color = secondary.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(dotX, dotY), size.width * 0.09, glowPaint);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.progress != progress;
}

// ─── Pulse Painter ───────────────────────────────────────────────────────────
class _PulsePainter extends CustomPainter {
  final double progress;
  final Color primary;
  final Color secondary;

  _PulsePainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final radius = phase * maxR;
      final opacity = (1.0 - phase) * 0.6;
      final color = Color.lerp(primary, secondary, phase)!;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius, paint);
    }

    // Markaziy nuqta
    final dotPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxR * 0.18, dotPaint);

    final glowPaint = Paint()
      ..color = primary.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, maxR * 0.22, glowPaint);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Modul uchun maxsus loading widget'lari
// ─────────────────────────────────────────────────────────────────────────────

/// Quiz uchun loading
class QuizLoadingWidget extends StatelessWidget {
  const QuizLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SozonaLoadingAnimation(
        style: LoadingStyle.wave,
        message: 'Savol tayyorlanmoqda...',
        primaryColor: Color(0xFF6C63FF),
        secondaryColor: Color(0xFFFF6584),
        size: 56,
      ),
    );
  }
}

/// Listening uchun loading
class ListeningLoadingWidget extends StatelessWidget {
  const ListeningLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SozonaLoadingAnimation(
        style: LoadingStyle.wave,
        message: 'Audio tayyorlanmoqda...',
        primaryColor: Color(0xFF00D4AA),
        secondaryColor: Color(0xFF6C63FF),
        size: 56,
      ),
    );
  }
}

/// Speaking uchun loading
class SpeakingLoadingWidget extends StatelessWidget {
  const SpeakingLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SozonaLoadingAnimation(
        style: LoadingStyle.orbit,
        message: 'AI tahlil qilmoqda...',
        primaryColor: Color(0xFFFF9F43),
        secondaryColor: Color(0xFF6C63FF),
        size: 56,
      ),
    );
  }
}

/// Flashcard / AI chat uchun loading
class AiThinkingWidget extends StatelessWidget {
  final String? message;
  const AiThinkingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SozonaLoadingAnimation(
        style: LoadingStyle.dots,
        message: message ?? "AI o'ylamoqda...",
        primaryColor: const Color(0xFF6C63FF),
        secondaryColor: const Color(0xFF00D4AA),
        size: 48,
      ),
    );
  }
}
