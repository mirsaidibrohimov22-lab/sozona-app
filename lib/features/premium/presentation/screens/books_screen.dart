// lib/features/premium/presentation/screens/books_screen.dart
// So'zona — Premium Kitoblar ekrani

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/features/auth/domain/entities/user_entity.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/presentation/providers/book_provider.dart';

const _levels = ['a1', 'a2', 'b1', 'b2', 'c1'];

const _levelInfo = {
  'a1': (
    label: 'A1',
    title: 'Boshlang\'ich',
    subtitle: 'Mutlaq yangi boshlovchilar uchun',
    emoji: '🌱',
    color: Color(0xFF22C55E),
  ),
  'a2': (
    label: 'A2',
    title: 'Asosiy',
    subtitle: 'Oddiy suhbatlar va kundalik hayot',
    emoji: '🌿',
    color: Color(0xFF16A34A),
  ),
  'b1': (
    label: 'B1',
    title: 'O\'rta',
    subtitle: 'Ko\'pchilik vaziyatlarni udda qilish',
    emoji: '⭐',
    color: Color(0xFF3B82F6),
  ),
  'b2': (
    label: 'B2',
    title: 'Yuqori o\'rta',
    subtitle: 'Murakkab mavzular va professional til',
    emoji: '🔥',
    color: Color(0xFF8B5CF6),
  ),
  'c1': (
    label: 'C1',
    title: 'Ilg\'or',
    subtitle: 'Akademik va intellektual ifoda',
    emoji: '👑',
    color: Color(0xFFFFD700),
  ),
};

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final language = user?.learningLanguage ?? LearningLanguage.english;
    final userLevel = user?.level.name.toLowerCase() ?? 'a1';
    final langName = language.name;
    final langLabel =
        language == LearningLanguage.english ? 'Ingliz tili' : 'Nemis tili';
    final langEmoji = language == LearningLanguage.english ? '🇬🇧' : '🇩🇪';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: Color(0xFFFFD700), size: 20),
            SizedBox(width: 8),
            Text('Kitoblar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Til banneri
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Text(langEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(langLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text('A1 dan C1 gacha — 5 ta kitob',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium,
                            color: Color(0xFFFFD700), size: 14),
                        SizedBox(width: 4),
                        Text('Premium',
                            style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ro'yxat
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: _levels.length,
              itemBuilder: (context, i) {
                final level = _levels[i];
                final info = _levelInfo[level]!;
                final isCurrent = level == userLevel;
                final downloadedAsync =
                    ref.watch(bookDownloadedProvider('${langName}_$level'));
                final isDownloaded = downloadedAsync.valueOrNull ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => context.push(RoutePaths.bookReaderPath(level)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent
                              ? (info.color).withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isCurrent ? 1.5 : 1,
                        ),
                        color: isCurrent
                            ? (info.color).withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.03),
                      ),
                      child: Row(
                        children: [
                          // Badge
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: (info.color).withValues(alpha: 0.15),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(info.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                Text(
                                  info.label,
                                  style: TextStyle(
                                    color: info.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Ma'lumot
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        info.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: (info.color)
                                              .withValues(alpha: 0.2),
                                        ),
                                        child: Text(
                                          'Sizning darajangiz',
                                          style: TextStyle(
                                              color: info.color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  info.subtitle,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.50),
                                      fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _Chip(
                                        icon: Icons.menu_book, label: '5 bob'),
                                    _Chip(
                                        icon: Icons.translate,
                                        label: '75+ so\'z'),
                                    if (isDownloaded)
                                      const _Chip(
                                        icon: Icons.download_done,
                                        label: 'Yuklangan',
                                        color: Color(0xFF22C55E),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withValues(alpha: 0.30),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.35);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c, size: 11),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: c, fontSize: 11)),
      ],
    );
  }
}
