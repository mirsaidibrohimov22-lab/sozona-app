// lib/features/student/home/presentation/widgets/quick_actions_widget.dart
// So'zona — Tezkor harakatlar (yangi rangli dizayn)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/features/student/home/presentation/providers/student_home_provider.dart';

/// Har bir modul uchun gradient ranglar
const _moduleGradients = {
  'Flashcard': [Color(0xFFFFB347), Color(0xFFFF8C42)],
  'Quiz': [Color(0xFF4FC3F7), Color(0xFF1976D2)],
  'Listening': [Color(0xFFCE93D8), Color(0xFF8E24AA)],
  'Speaking': [Color(0xFF80CBC4), Color(0xFF00897B)],
  'AI Chat': [Color(0xFFA78BFA), Color(0xFF6C63FF)],
  // ✅ FIX: AI Murabbiy uchun oltin gradient
  'AI Murabbiy': [Color(0xFFFFD700), Color(0xFFFF8C00)],
  'Sinfim': [Color(0xFF81C784), Color(0xFF388E3C)],
  'Artikel': [Color(0xFFF48FB1), Color(0xFFD81B60)],
};

const _moduleIcons = {
  'Flashcard': '📝',
  'Quiz': '🧠',
  'Listening': '🎧',
  'Speaking': '🗣️',
  'AI Chat': '🤖',
  'AI Murabbiy': '🎓', // ✅ FIX: premium uchun
  'Sinfim': '🏫',
  'Artikel': '🇩🇪',
};

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(quickActionsProvider);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.spacingSm + 2,
        mainAxisSpacing: AppSizes.spacingSm + 2,
        childAspectRatio: 0.88,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _QuickActionItem(action: actions[index]);
      },
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final QuickAction action;
  const _QuickActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final gradientColors = _moduleGradients[action.title] ??
        [const Color(0xFF6C63FF), const Color(0xFF4A42D6)];
    final emoji = _moduleIcons[action.title] ?? action.icon;

    return GestureDetector(
      onTap: () => context.push(action.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              // ✅ FIX: Color(x.value) o'rniga to'g'ridan-to'g'ri color ishlatildi
              color: gradientColors[0].withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            // ✅ FIX: Color(x.value) o'rniga to'g'ridan-to'g'ri color ishlatildi
            color: gradientColors[0].withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              action.title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                // ✅ FIX: Color(x.value) o'rniga to'g'ridan-to'g'ri color ishlatildi
                color: gradientColors[1],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 2),

            Text(
              action.subtitle,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
