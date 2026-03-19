// lib/features/student/artikel/presentation/screens/artikel_list_screen.dart
// ✅ PATCH DAY-2: Empty state yaxshilandi, UI tuzatildi

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/artikel/presentation/providers/artikel_provider.dart';
import 'package:my_first_app/features/student/artikel/presentation/screens/artikel_practice_screen.dart';
import 'package:my_first_app/features/student/artikel/presentation/widgets/artikel_card.dart';

class ArtikelListScreen extends ConsumerWidget {
  const ArtikelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authNotifierProvider).user?.id ?? '';
    final wordsAsync = ref.watch(artikelWordsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artikel (der/die/das)'),
      ),
      body: wordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppEmptyWidget(
          icon: Icons.error_outline,
          title: 'Xatolik yuz berdi',
          message: e.toString(),
          actionLabel: 'Qayta urinish',
          onAction: () => ref.invalidate(artikelWordsProvider(uid)),
        ),
        data: (words) {
          if (words.isEmpty) {
            return AppEmptyWidget(
              icon: Icons.translate_outlined,
              title: 'So\'zlar topilmadi',
              message:
                  'Nemis tili so\'zlari hali qo\'shilmagan.\nTez orada yangilanadi!',
            );
          }

          return Column(
            children: [
              // ── Mashq boshlash tugmasi ──
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacingLg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtikelPracticeScreen(words: words),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text('Mashq boshlash (${words.length} so\'z)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.spacingMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),

              // ── So'zlar ro'yxati ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingLg,
                  ),
                  itemCount: words.length,
                  itemBuilder: (_, i) => ArtikelCard(word: words[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
