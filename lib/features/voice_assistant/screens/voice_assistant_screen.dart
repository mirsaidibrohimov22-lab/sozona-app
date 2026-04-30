// lib/features/voice_assistant/screens/voice_assistant_screen.dart
// ✅ YANGI FAYL — mavjud kodlarga tegmaydi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ✅ TUZATILDI: core/constants ishlatiladi (core/theme emas)
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/features/voice_assistant/providers/voice_assistant_provider.dart';
import 'package:my_first_app/features/voice_assistant/services/voice_assistant_service.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _rippleCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _pulseAnim = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(voiceAssistantProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "So'zona Yordamchi",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (ui.isPremium) _premiumBadge(),
          const SizedBox(width: 12),
        ],
      ),
      body: ui.isPremium ? _activeBody(ui) : _premiumGate(),
    );
  }

  // ── Premium yo'q ──────────────────────────────
  Widget _premiumGate() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.streakGradient,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 28,
                        spreadRadius: 4)
                  ],
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Premium Funksiya',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Ovozli yordamchi faqat Premium\nfoydalanuvchilar uchun mavjud',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 15,
                    height: 1.6),
              ),
              const SizedBox(height: 32),
              _gradientBtn('Premium olish', () => context.pop()),
            ],
          ),
        ),
      );

  // ── Asosiy UI ─────────────────────────────────
  Widget _activeBody(VoiceAssistantUiState ui) => SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _statusBadge(ui.assistantState),
            const SizedBox(height: 16),
            Expanded(child: Center(child: _orb(ui))),
            // Matn
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: ui.displayText.isNotEmpty
                  ? Padding(
                      key: ValueKey(ui.displayText.hashCode),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        ui.displayText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, height: 1.6),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            Text(
              _hint(ui.assistantState),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 13),
            ),
            const SizedBox(height: 36),
            _gradientBtn(
              ui.isActive || ui.isSpeaking || ui.isWaitingInput
                  ? "To'xtatish"
                  : "Qo'lda boshlash",
              () async {
                final n = ref.read(voiceAssistantProvider.notifier);
                if (ui.isActive || ui.isSpeaking || ui.isWaitingInput) {
                  await n.stop();
                } else {
                  await n.triggerManually();
                }
              },
            ),
            const SizedBox(height: 44),
          ],
        ),
      );

  // ── Orb ──────────────────────────────────────
  Widget _orb(VoiceAssistantUiState ui) {
    final color = _color(ui.assistantState);
    final on = ui.isActive ||
        ui.isSpeaking ||
        ui.isWaitingInput ||
        ui.assistantState == VoiceAssistantState.listening;

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(alignment: Alignment.center, children: [
        if (on)
          AnimatedBuilder(
            animation: _rippleCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(240, 240),
              painter:
                  _RipplePainter(progress: _rippleCtrl.value, color: color),
            ),
          ),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) =>
              Transform.scale(scale: on ? _pulseAnim.value : 1.0, child: child),
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                color.withOpacity(0.95),
                color.withOpacity(0.35),
              ]),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.50),
                    blurRadius: 44,
                    spreadRadius: 10)
              ],
            ),
            child:
                Icon(_icon(ui.assistantState), color: Colors.white, size: 52),
          ),
        ),
      ]),
    );
  }

  // ── Yordamchi widgetlar ───────────────────────
  Widget _statusBadge(VoiceAssistantState s) {
    final (label, color) = _labelColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _premiumBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppColors.streakGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.workspace_premium,
              color: Color.fromARGB(255, 86, 119, 151), size: 14),
          SizedBox(width: 4),
          Text('Premium',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _gradientBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      );

  // ── Mapping ───────────────────────────────────
  Color _color(VoiceAssistantState s) => switch (s) {
        VoiceAssistantState.listening => AppColors.info,
        VoiceAssistantState.speaking => AppColors.primary,
        VoiceAssistantState.waitingInput => AppColors.success,
        VoiceAssistantState.activated => AppColors.accent,
        _ => AppColors.textTertiary,
      };

  IconData _icon(VoiceAssistantState s) => switch (s) {
        VoiceAssistantState.listening => Icons.hearing_rounded,
        VoiceAssistantState.speaking => Icons.record_voice_over_rounded,
        VoiceAssistantState.waitingInput => Icons.mic_rounded,
        VoiceAssistantState.activated => Icons.bolt_rounded,
        _ => Icons.mic_off_rounded,
      };

  (String, Color) _labelColor(VoiceAssistantState s) => switch (s) {
        VoiceAssistantState.listening => ('Tinglayapti', AppColors.info),
        VoiceAssistantState.speaking => ('Gapirmoqda', AppColors.primary),
        VoiceAssistantState.waitingInput => (
            'Sizni kutmoqda',
            AppColors.success
          ),
        VoiceAssistantState.activated => ('Faol', AppColors.accent),
        _ => ('Yoqilmagan', AppColors.textTertiary),
      };

  String _hint(VoiceAssistantState s) => switch (s) {
        VoiceAssistantState.listening => '"Salom So\'zona" deb chaqiring',
        VoiceAssistantState.speaking => 'Gapirmoqda...',
        VoiceAssistantState.waitingInput => 'Gapiring...',
        _ => '',
      };
}

// ── Ripple Painter ────────────────────────────
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        65 + (size.width / 2 - 65) * p,
        Paint()
          ..color = color.withOpacity((1 - p) * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
