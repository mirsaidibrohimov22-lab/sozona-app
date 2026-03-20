// QO'YISH: lib/features/profile/presentation/screens/settings_screen.dart
// So'zona — Sozlamalar ekrani

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/core/constants/app_colors.dart';
import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/profile/presentation/providers/profile_provider.dart';
// ignore: unused_import
import 'package:my_first_app/core/utils/seed_data.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).profile;
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Mikro-sessiya'),
          if (profile != null)
            SwitchListTile(
              title: const Text('Mikro-sessiya yoqilgan'),
              subtitle: const Text('Har 1 soatda 10 daqiqa mashq'),
              value: profile.preferences.microSessionEnabled,
              // ✅ activeColor ishlatiladi (Flutter 3.27 da activeThumbColor yo'q)
              activeColor: AppColors.primary,
              onChanged: (v) =>
                  ref.read(profileProvider.notifier).updatePreferences(
                        user!.id,
                        profile.preferences.copyWith(microSessionEnabled: v),
                      ),
            ),
          const _SectionHeader(title: 'Bildirishnomalar'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Bildirishnoma sozlamalari'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.push(RoutePaths.notifications),
          ),
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
        ],
      ),
    );
  }

  void _requestExport(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final ok =
        await ref.read(profileProvider.notifier).requestDataExport(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? "So'rov yuborildi — email orqali xabardor qilamiz"
                : 'Xatolik yuz berdi',
          ),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hisobni o'chirish"),
        content: const Text(
          "Barcha ma'lumotlaringiz o'chib ketadi. Davom etasizmi?",
        ),
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
                  const SnackBar(content: Text("So'rov qabul qilindi")),
                );
              }
            },
            child: const Text("O'chirish", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

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
