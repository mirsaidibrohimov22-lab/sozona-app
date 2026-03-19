// QO'YISH: lib/features/teacher/content_generator/presentation/widgets/generation_progress.dart
// Generation Progress Widget — AI kontent yaratayotgan paytdagi progress ko'rsatkichi

import 'package:flutter/material.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';

/// Generation Progress Widget
///
/// Bolaga: AI kontent yaratayotgan paytda bu widget chiqib,
/// "AI ishlayapti, bir oz kuting" degan animatsiya ko'rsatadi.
class GenerationProgress extends StatefulWidget {
  final String contentType; // quiz, flashcard, listening
  final String? message; // Custom xabar (ixtiyoriy)

  const GenerationProgress({
    super.key,
    required this.contentType,
    this.message,
  });

  @override
  State<GenerationProgress> createState() => _GenerationProgressState();
}

class _GenerationProgressState extends State<GenerationProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<String> _loadingMessages = [];
  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Loading messages'ni tayyorlash
    _loadingMessages.addAll(_getLoadingMessages());

    // Har 3 soniyada xabarni o'zgartirish
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated AI icon
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_animation.value * 0.2),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            widget.message ?? 'AI kontent yaratyapti...',
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Rotating message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loadingMessages[_currentMessageIndex],
              key: ValueKey<int>(_currentMessageIndex),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Progress indicator
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(),
          ),
          const SizedBox(height: 12),

          // Time estimate
          Text(
            'Bu 20-30 soniya davom etishi mumkin',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Content turiga qarab loading messages
  List<String> _getLoadingMessages() {
    switch (widget.contentType.toLowerCase()) {
      case 'quiz':
        return [
          '🤔 Savollar o\'ylab topilmoqda...',
          '✍️ Javob variantlari tayyorlanmoqda...',
          '💡 Tushuntirishlar yozilmoqda...',
          '🎯 Qiyinchilik darajasi sozlanmoqda...',
          '✨ Yakuniy tekshiruvlar...',
        ];

      case 'speaking':
      case 'flashcard':
        return [
          '📚 So\'zlar tanlanmoqda...',
          '🔤 Tarjimalar tayyorlanmoqda...',
          '🗣️ Talaffuzlar qo\'shilmoqda...',
          '📝 Misol gaplar yozilmoqda...',
          '✨ Kartochkalar tugallanmoqda...',
        ];

      case 'listening':
        return [
          '📖 Matn yozilmoqda...',
          '🎤 Transkripsiya tayyorlanmoqda...',
          '❓ Savollar yaratilmoqda...',
          '🎧 Audio tayyorlanmoqda...',
          '✨ Yakuniy sozlanmoqda...',
        ];

      default:
        return [
          '🤖 AI ishlayapti...',
          '⚙️ Kontent tayyorlanmoqda...',
          '✨ Deyarli tayyor...',
        ];
    }
  }
}

/// Generation Progress Dialog
///
/// Modal dialog sifatida ko'rsatish uchun
class GenerationProgressDialog extends StatelessWidget {
  final String contentType;
  final String? message;

  const GenerationProgressDialog({
    super.key,
    required this.contentType,
    this.message,
  });

  /// Dialog'ni ko'rsatish
  static void show(
    BuildContext context, {
    required String contentType,
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Dismiss qilish mumkin emas
      builder: (context) => GenerationProgressDialog(
        contentType: contentType,
        message: message,
      ),
    );
  }

  /// Dialog'ni yopish
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: GenerationProgress(
        contentType: contentType,
        message: message,
      ),
    );
  }
}
