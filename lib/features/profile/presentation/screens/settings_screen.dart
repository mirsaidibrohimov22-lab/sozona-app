// lib/features/profile/presentation/screens/settings_screen.dart
// ✅ YANGILANDI — "Ovozli yordamchi" bo'limi qo'shildi

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/utils/seed_data.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/premium/presentation/providers/premium_provider.dart';
import 'package:my_first_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:my_first_app/features/voice_assistant/providers/voice_assistant_provider.dart';
import 'package:my_first_app/features/voice_assistant/providers/voice_assistant_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).profile;
    final user = ref.watch(authNotifierProvider).user;
    final hasPremium = ref.watch(hasPremiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        children: [
          // ── Mikro-sessiya ──
          const _SectionHeader(title: 'Mikro-sessiya'),
          if (profile != null)
            SwitchListTile(
              title: const Text('Mikro-sessiya yoqilgan'),
              subtitle: const Text('Har 1 soatda 10 daqiqa mashq'),
              value: profile.preferences.microSessionEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (v) =>
                  ref.read(profileProvider.notifier).updatePreferences(
                        user!.id,
                        profile.preferences.copyWith(microSessionEnabled: v),
                      ),
            ),

          // ── Ovozli yordamchi ──
          const _SectionHeader(title: "So'zona Ovozli Yordamchi"),
          _VoiceAssistantSection(hasPremium: hasPremium),

          // ── Bildirishnomalar ──
          const _SectionHeader(title: 'Bildirishnomalar'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Bildirishnoma sozlamalari'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.push(RoutePaths.notifications),
          ),

          // ── Maxfiylik ──
          const _SectionHeader(title: "Maxfiylik va ma'lumotlar"),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Maxfiylik siyosati'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.push(RoutePaths.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text("Ma'lumotlarimni yuklab olish"),
            onTap: () => _requestExport(context, ref, user?.id ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Hisobni o'chirish",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmDelete(context, ref, user?.id ?? ''),
          ),

          // ── Ilova haqida ──
          const _SectionHeader(title: 'Ilova haqida'),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.orange),
              title: const Text("Test data qo'shish (DEBUG)"),
              subtitle: const Text('Faqat developer uchun'),
              onTap: () => SeedData.run(context),
            ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versiya'),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _requestExport(
      BuildContext context, WidgetRef ref, String userId) async {
    final ok =
        await ref.read(profileProvider.notifier).requestDataExport(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? "So'rov yuborildi — email orqali xabardor qilamiz"
            : 'Xatolik yuz berdi'),
      ));
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hisobni o'chirish"),
        content: const Text(
            "Barcha ma'lumotlaringiz o'chib ketadi. Davom etasizmi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(profileProvider.notifier)
                  .requestAccountDelete(userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("So'rov qabul qilindi")));
              }
            },
            child: const Text("O'chirish", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// OVOZLI YORDAMCHI BO'LIMI
// ══════════════════════════════════════════════════
class _VoiceAssistantSection extends ConsumerWidget {
  final bool hasPremium;
  const _VoiceAssistantSection({required this.hasPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(voiceAssistantSettingsProvider);
    final notifier = ref.read(voiceAssistantSettingsProvider.notifier);

    // Premium emas — lock ko'rsat
    if (!hasPremium) {
      return ListTile(
        leading: const Icon(Icons.record_voice_over_outlined),
        title: const Text('Ovozli yordamchi sozlamalari'),
        subtitle: const Text('Faqat Premium foydalanuvchilar uchun'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: AppColors.streakGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Premium',
              style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
        onTap: () => context.push(RoutePaths.voiceAssistant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ovoz tanlash ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            'Ovoz turi',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ),
        ...SozanaVoice.values.map((v) {
          final selected = settings.voice == v;
          return InkWell(
            onTap: () async {
              await notifier.setVoice(v);
              // Servisni qayta ishga tushir
              ref.read(voiceAssistantProvider.notifier).reinitialize();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(v.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? AppColors.primary : null,
                          ),
                        ),
                        if (v == SozanaVoice.nova)
                          const Text('Ko\'pchilik uchun tavsiya etiladi',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 8),

        // ── Fon servisi toggle ──
        SwitchListTile(
          title: const Text('Fonda tinglash'),
          subtitle: const Text(
            'Ekran o\'chiq bo\'lsaham "Salom So\'zona" deb chaqirish mumkin',
            style: TextStyle(fontSize: 12),
          ),
          value: settings.backgroundEnabled,
          activeThumbColor: AppColors.primary,
          onChanged: (v) async {
            await notifier.setBackgroundEnabled(v);
            ref.read(voiceAssistantProvider.notifier).reinitialize();
          },
        ),

        // ── Ochish tugmasi ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: OutlinedButton.icon(
            onPressed: () => context.push(RoutePaths.voiceAssistant),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Ovozli yordamchini ochish'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      );
}
