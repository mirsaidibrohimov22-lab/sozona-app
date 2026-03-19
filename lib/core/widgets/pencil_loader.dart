// ✅ TUZATILDI: withOpacity → withValues (deprecated warning yo'qotildi)
import 'dart:math' as math;
import 'package:flutter/material.dart';

class PencilLoader extends StatefulWidget {
  const PencilLoader({
    super.key,
    this.size = 180,
    this.strokeWidth = 10,
    this.duration = const Duration(milliseconds: 1600),
  });

  final double size;
  final double strokeWidth;
  final Duration duration;

  @override
  State<PencilLoader> createState() => _PencilLoaderState();
}

class _PencilLoaderState extends State<PencilLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return CustomPaint(
            painter: _PencilPainter(
              t: _c.value,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _PencilPainter extends CustomPainter {
  _PencilPainter({required this.t, required this.strokeWidth});

  final double t; // 0..1
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;

    canvas.saveLayer(Offset.zero & size, Paint());

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      // ✅ TUZATILDI: withOpacity → withValues
      ..color = Colors.white.withValues(alpha: 0.9);

    final drawPhase = t < 0.5;
    final p = drawPhase ? (t / 0.5) : ((t - 0.5) / 0.5);

    final startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * p;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      ringPaint,
    );

    if (!drawPhase) {
      final clearPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth + 1
        ..blendMode = BlendMode.clear;

      final eraseSweep = 2 * math.pi * p;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        eraseSweep,
        false,
        clearPaint,
      );
    }

    final angle = startAngle + 2 * math.pi * t;

    final tipPos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final bodyLen = radius * 0.28;
    final bodyDir = Offset(math.cos(angle), math.sin(angle));
    final bodyStart = tipPos - bodyDir * bodyLen;
    final bodyEnd = tipPos + bodyDir * (bodyLen * 0.55);

    final bodyPaint = Paint()
      ..strokeWidth = strokeWidth * 0.55
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    canvas.drawLine(bodyStart, bodyEnd, bodyPaint);

    final tipPaint = Paint()..color = Colors.white;
    canvas.drawCircle(tipPos, strokeWidth * 0.32, tipPaint);

    final eraserPos = bodyStart;
    // ✅ TUZATILDI: withOpacity → withValues
    final eraserPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(eraserPos, strokeWidth * 0.38, eraserPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PencilPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.strokeWidth != strokeWidth;
}
